import Foundation
import IPADomain
import ZIPFoundation

public struct ValidatedArchiveEntry: Hashable, Sendable {
    public let descriptor: ArchiveEntryDescriptor
    public let normalizedPath: String
}

public struct ArchivePreflightResult: Hashable, Sendable {
    public let entries: [ValidatedArchiveEntry]
    public let rootApplicationRelativePath: String
    public let totalUncompressedBytes: UInt64

    public init(
        entries: [ValidatedArchiveEntry],
        rootApplicationRelativePath: String,
        totalUncompressedBytes: UInt64
    ) {
        self.entries = entries
        self.rootApplicationRelativePath = rootApplicationRelativePath
        self.totalUncompressedBytes = totalUncompressedBytes
    }
}

public struct ArchivePreflightValidator: Sendable {
    public let policy: ArchiveSafetyPolicy

    public init(policy: ArchiveSafetyPolicy = .default) {
        self.policy = policy
    }

    public func preflight(archiveAt url: URL) throws -> ArchivePreflightResult {
        let declaredEntryCount = try declaredEntryCount(at: url)
        guard declaredEntryCount <= policy.maximumEntryCount else {
            throw IPAError.tooManyArchiveEntries(maximumCount: policy.maximumEntryCount)
        }
        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw IPAError.unsupportedArchive
        }

        var descriptors: [ArchiveEntryDescriptor] = []
        descriptors.reserveCapacity(min(policy.maximumEntryCount, 256))
        for entry in archive {
            guard descriptors.count < policy.maximumEntryCount else {
                throw IPAError.tooManyArchiveEntries(maximumCount: policy.maximumEntryCount)
            }
            descriptors.append(ArchiveEntryDescriptor(
                path: entry.path,
                compressedSize: entry.compressedSize,
                uncompressedSize: entry.uncompressedSize,
                checksum: entry.checksum,
                kind: kind(for: entry.type)
            ))
        }
        guard descriptors.count == declaredEntryCount else {
            throw IPAError.inspectionFailure
        }
        guard !descriptors.isEmpty else { throw IPAError.unsupportedArchive }

        let validation = try policy.validationResult(for: descriptors)
        let rootPath = try rootApplicationPath(in: validation.normalizedPaths)
        return ArchivePreflightResult(
            entries: zip(descriptors, validation.normalizedPaths).map {
                ValidatedArchiveEntry(descriptor: $0.0, normalizedPath: $0.1)
            },
            rootApplicationRelativePath: rootPath,
            totalUncompressedBytes: validation.totalUncompressedBytes
        )
    }

    public func rootApplicationPath(in normalizedPaths: [String]) throws -> String {
        var sawPayload = false
        var applications = Set<String>()

        for path in normalizedPaths {
            let parts = path.split(separator: "/", omittingEmptySubsequences: false)
            guard let first = parts.first, first == "Payload" else { continue }
            sawPayload = true
            guard parts.count >= 2,
                  parts[1].count > 4,
                  parts[1].lowercased().hasSuffix(".app")
            else { continue }
            applications.insert("Payload/\(parts[1])")
        }

        guard sawPayload else { throw IPAError.invalidPayloadStructure }
        guard !applications.isEmpty else { throw IPAError.missingApplicationBundle }
        guard applications.count == 1, let application = applications.first else {
            throw IPAError.multipleRootApplications
        }
        return application
    }

    private func kind(for type: Entry.EntryType) -> ArchiveEntryKind {
        switch type {
        case .file: .file
        case .directory: .directory
        case .symlink: .symbolicLink
        }
    }

    private func declaredEntryCount(at url: URL) throws -> Int {
        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: [
                .fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey,
            ])
        } catch {
            throw IPAError.unsupportedArchive
        }
        guard values.isRegularFile == true,
              values.isSymbolicLink != true,
              let fileSize = values.fileSize,
              fileSize > 0
        else {
            throw IPAError.unsupportedArchive
        }
        guard UInt64(fileSize) <= policy.maximumSourceIPABytes else {
            throw IPAError.sourceTooLarge(maximumBytes: policy.maximumSourceIPABytes)
        }

        let maximumEnvelopeBytes = 65_557
        let readCount = min(fileSize, maximumEnvelopeBytes)
        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            throw IPAError.unsupportedArchive
        }
        defer { try? handle.close() }

        let envelope: Data
        do {
            try handle.seek(toOffset: UInt64(fileSize - readCount))
            envelope = try handle.read(upToCount: readCount) ?? Data()
        } catch {
            throw IPAError.unsupportedArchive
        }
        guard envelope.count >= 22 else { throw IPAError.unsupportedArchive }

        for index in stride(from: envelope.count - 22, through: 0, by: -1) {
            guard uint32(envelope, at: index) == 0x0605_4B50 else { continue }
            let commentLength = Int(uint16(envelope, at: index + 20))
            guard index + 22 + commentLength == envelope.count else { continue }

            let diskNumber = uint16(envelope, at: index + 4)
            let centralDirectoryDisk = uint16(envelope, at: index + 6)
            let entriesOnDisk = uint16(envelope, at: index + 8)
            let totalEntries = uint16(envelope, at: index + 10)
            guard diskNumber == 0,
                  centralDirectoryDisk == 0,
                  entriesOnDisk == totalEntries
            else {
                throw IPAError.unsupportedArchive
            }

            let centralSize = uint32(envelope, at: index + 12)
            let centralOffset = uint32(envelope, at: index + 16)
            if centralSize != UInt32.max, centralOffset != UInt32.max {
                let (centralEnd, overflow) = UInt64(centralOffset).addingReportingOverflow(UInt64(centralSize))
                let endRecordOffset = UInt64(fileSize - readCount + index)
                guard !overflow, centralEnd <= endRecordOffset else {
                    throw IPAError.unsupportedArchive
                }
            }
            return Int(totalEntries)
        }
        throw IPAError.unsupportedArchive
    }

    private func uint16(_ data: Data, at index: Int) -> UInt16 {
        UInt16(data[index]) | (UInt16(data[index + 1]) << 8)
    }

    private func uint32(_ data: Data, at index: Int) -> UInt32 {
        UInt32(data[index])
            | (UInt32(data[index + 1]) << 8)
            | (UInt32(data[index + 2]) << 16)
            | (UInt32(data[index + 3]) << 24)
    }
}
