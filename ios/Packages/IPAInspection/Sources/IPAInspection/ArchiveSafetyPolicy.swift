import Foundation
import IPADomain

public enum ArchiveEntryKind: Hashable, Sendable {
    case file
    case directory
    case symbolicLink
}

public struct ArchiveEntryDescriptor: Hashable, Sendable {
    public let path: String
    public let compressedSize: UInt64
    public let uncompressedSize: UInt64
    public let checksum: UInt32
    public let kind: ArchiveEntryKind

    public init(
        path: String,
        compressedSize: UInt64,
        uncompressedSize: UInt64,
        checksum: UInt32 = 0,
        kind: ArchiveEntryKind = .file
    ) {
        self.path = path
        self.compressedSize = compressedSize
        self.uncompressedSize = uncompressedSize
        self.checksum = checksum
        self.kind = kind
    }
}

struct ArchiveSafetyValidationResult: Hashable, Sendable {
    let normalizedPaths: [String]
    let totalUncompressedBytes: UInt64

    init(normalizedPaths: [String], totalUncompressedBytes: UInt64) {
        self.normalizedPaths = normalizedPaths
        self.totalUncompressedBytes = totalUncompressedBytes
    }
}

public struct ArchiveSafetyPolicy: Hashable, Sendable {
    /// The compressed import limit retained from Phase 1A.
    public var maximumSourceIPABytes: UInt64
    /// 10,000 entries accommodates ordinary app bundles without permitting inode-exhaustion archives.
    public var maximumEntryCount: Int
    /// Extraction is capped at 8 GiB, twice the maximum compressed source size.
    public var maximumTotalUncompressedBytes: UInt64
    /// Inspection preserves 512 MiB beyond the archive's declared extraction footprint.
    public var inspectionStorageSafetyReserveBytes: UInt64
    /// No individual bundle resource may expand beyond 512 MiB.
    public var maximumEntryUncompressedBytes: UInt64
    /// Entries expanding beyond 200:1 are rejected in addition to the absolute byte limits.
    public var maximumCompressionRatio: UInt64
    /// Paths are bounded by UTF-8 byte count before they reach the filesystem.
    public var maximumPathBytes: Int
    /// Deep path trees are bounded to avoid pathological filesystem work.
    public var maximumNestingDepth: Int
    public var maximumInfoPlistBytes: UInt64
    public var maximumMetadataStringBytes: Int
    public var maximumInfoPlistTraversalValueCount: Int
    public var maximumIconDeclarationCount: Int
    public var maximumDeviceFamilyCount: Int
    public var maximumProvisioningProfileBytes: UInt64
    public var maximumIconBytes: UInt64
    public var maximumIconPixelDimension: Int
    public var maximumIconPixelCount: UInt64
    public var maximumProvisioningValueCount: Int

    public init(
        maximumSourceIPABytes: UInt64 = 4 * 1_024 * 1_024 * 1_024,
        maximumEntryCount: Int = 10_000,
        maximumTotalUncompressedBytes: UInt64 = 8 * 1_024 * 1_024 * 1_024,
        inspectionStorageSafetyReserveBytes: UInt64 = 512 * 1_024 * 1_024,
        maximumEntryUncompressedBytes: UInt64 = 512 * 1_024 * 1_024,
        maximumCompressionRatio: UInt64 = 200,
        maximumPathBytes: Int = 1_024,
        maximumNestingDepth: Int = 32,
        maximumInfoPlistBytes: UInt64 = 4 * 1_024 * 1_024,
        maximumMetadataStringBytes: Int = 1_024,
        maximumInfoPlistTraversalValueCount: Int = 4_096,
        maximumIconDeclarationCount: Int = 128,
        maximumDeviceFamilyCount: Int = 16,
        maximumProvisioningProfileBytes: UInt64 = 4 * 1_024 * 1_024,
        maximumIconBytes: UInt64 = 32 * 1_024 * 1_024,
        maximumIconPixelDimension: Int = 4_096,
        maximumIconPixelCount: UInt64 = 16_777_216,
        maximumProvisioningValueCount: Int = 4_096
    ) {
        self.maximumSourceIPABytes = maximumSourceIPABytes
        self.maximumEntryCount = maximumEntryCount
        self.maximumTotalUncompressedBytes = maximumTotalUncompressedBytes
        self.inspectionStorageSafetyReserveBytes = inspectionStorageSafetyReserveBytes
        self.maximumEntryUncompressedBytes = maximumEntryUncompressedBytes
        self.maximumCompressionRatio = maximumCompressionRatio
        self.maximumPathBytes = maximumPathBytes
        self.maximumNestingDepth = maximumNestingDepth
        self.maximumInfoPlistBytes = maximumInfoPlistBytes
        self.maximumMetadataStringBytes = maximumMetadataStringBytes
        self.maximumInfoPlistTraversalValueCount = maximumInfoPlistTraversalValueCount
        self.maximumIconDeclarationCount = maximumIconDeclarationCount
        self.maximumDeviceFamilyCount = maximumDeviceFamilyCount
        self.maximumProvisioningProfileBytes = maximumProvisioningProfileBytes
        self.maximumIconBytes = maximumIconBytes
        self.maximumIconPixelDimension = maximumIconPixelDimension
        self.maximumIconPixelCount = maximumIconPixelCount
        self.maximumProvisioningValueCount = maximumProvisioningValueCount
    }

    public static let `default` = ArchiveSafetyPolicy()

    @discardableResult
    public func validate(_ entries: [ArchiveEntryDescriptor]) throws -> [String] {
        try validationResult(for: entries).normalizedPaths
    }

    func validationResult(
        for entries: [ArchiveEntryDescriptor]
    ) throws -> ArchiveSafetyValidationResult {
        guard entries.count <= maximumEntryCount else {
            throw IPAError.tooManyArchiveEntries(maximumCount: maximumEntryCount)
        }

        var normalizedPaths: [String] = []
        normalizedPaths.reserveCapacity(entries.count)
        var seen = Set<String>()
        var kindsByDestination = [String: ArchiveEntryKind]()
        var total: UInt64 = 0

        for entry in entries {
            let normalized = try normalizedPath(entry.path)
            let destinationKey = normalizedDestinationKey(normalized)
            guard seen.insert(destinationKey).inserted else {
                throw IPAError.duplicateArchiveEntry
            }
            kindsByDestination[destinationKey] = entry.kind
            guard entry.kind != .symbolicLink else {
                throw IPAError.unsafeArchive("symbolic links are not accepted")
            }
            guard entry.uncompressedSize <= maximumEntryUncompressedBytes else {
                throw IPAError.archiveEntryTooLarge(maximumBytes: maximumEntryUncompressedBytes)
            }

            let (newTotal, overflow) = total.addingReportingOverflow(entry.uncompressedSize)
            guard !overflow, newTotal <= maximumTotalUncompressedBytes else {
                throw IPAError.archiveTooLarge(maximumBytes: maximumTotalUncompressedBytes)
            }
            total = newTotal

            if entry.compressedSize == 0 {
                guard entry.uncompressedSize == 0 else {
                    throw IPAError.unsafeArchive("invalid compression metadata")
                }
            } else {
                let (allowedSize, ratioOverflow) = entry.compressedSize.multipliedReportingOverflow(
                    by: maximumCompressionRatio
                )
                if !ratioOverflow, entry.uncompressedSize > allowedSize {
                    throw IPAError.suspiciousCompressionRatio(maximumRatio: maximumCompressionRatio)
                }
            }

            normalizedPaths.append(normalized)
        }

        for path in normalizedPaths {
            let components = path.split(separator: "/")
            guard components.count > 1 else { continue }
            for prefixLength in 1..<components.count {
                let prefix = components.prefix(prefixLength).joined(separator: "/")
                guard kindsByDestination[normalizedDestinationKey(prefix)] != .file else {
                    throw IPAError.unsafeArchive("a file entry cannot contain child entries")
                }
            }
        }
        return ArchiveSafetyValidationResult(
            normalizedPaths: normalizedPaths,
            totalUncompressedBytes: total
        )
    }

    public func normalizedPath(_ path: String) throws -> String {
        guard !path.isEmpty,
              !path.hasPrefix("/"),
              !path.contains("\\"),
              !path.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
        else {
            throw IPAError.unsafeArchive("invalid archive path")
        }

        let withoutDirectoryMarker = path.hasSuffix("/") ? String(path.dropLast()) : path
        guard !withoutDirectoryMarker.isEmpty,
              withoutDirectoryMarker.utf8.count <= maximumPathBytes
        else {
            throw IPAError.unsafeArchive("archive path limit exceeded")
        }

        let components = withoutDirectoryMarker.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count <= maximumNestingDepth else {
            throw IPAError.unsafeArchive("archive nesting limit exceeded")
        }
        guard !components.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." }) else {
            throw IPAError.unsafeArchive("archive path traversal")
        }
        if let first = components.first,
           first.count >= 2,
           first[first.index(after: first.startIndex)] == ":",
           first.first?.isASCII == true,
           first.first?.isLetter == true {
            throw IPAError.unsafeArchive("absolute archive path")
        }

        return withoutDirectoryMarker.precomposedStringWithCanonicalMapping
    }

    public func destinationURL(for normalizedPath: String, inside root: URL) throws -> URL {
        let rootURL = root.standardizedFileURL.resolvingSymlinksInPath()
        let components = normalizedPath.split(separator: "/").map(String.init)
        let candidate = components.reduce(rootURL) { partial, component in
            partial.appending(path: component)
        }.standardizedFileURL
        guard contains(candidate, inside: rootURL) else {
            throw IPAError.unsafeArchive("archive destination escaped its workspace")
        }
        return candidate
    }

    public func contains(_ candidate: URL, inside root: URL) -> Bool {
        let rootComponents = root.standardizedFileURL.pathComponents
        let candidateComponents = candidate.standardizedFileURL.pathComponents
        guard candidateComponents.count > rootComponents.count else { return false }
        return candidateComponents.prefix(rootComponents.count).elementsEqual(rootComponents)
    }

    private func normalizedDestinationKey(_ path: String) -> String {
        path.folding(
            options: [.caseInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
    }
}
