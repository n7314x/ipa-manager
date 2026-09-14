import Foundation
import IPADomain
import ZIPFoundation

struct SafeArchiveExtractor {
    let policy: ArchiveSafetyPolicy

    func extract(
        archiveAt source: URL,
        preflight: ArchivePreflightResult,
        to extractionRoot: URL,
        fileManager: FileManager
    ) throws {
        let archive: Archive
        do {
            archive = try Archive(url: source, accessMode: .read)
        } catch {
            throw IPAError.inspectionFailure
        }

        let expected = Dictionary(uniqueKeysWithValues: preflight.entries.map { ($0.normalizedPath, $0.descriptor) })
        var extracted = Set<String>()
        var actualTotal: UInt64 = 0

        do {
            for entry in archive {
                try Task.checkCancellation()
                let normalized = try policy.normalizedPath(entry.path)
                guard let descriptor = expected[normalized], extracted.insert(normalized).inserted else {
                    throw IPAError.unsafeArchive("archive entries changed after preflight")
                }
                guard archiveKind(for: entry.type) == descriptor.kind else {
                    throw IPAError.unsafeArchive("archive entry type changed after preflight")
                }
                guard entry.checksum == descriptor.checksum,
                      entry.compressedSize == descriptor.compressedSize,
                      entry.uncompressedSize == descriptor.uncompressedSize
                else {
                    throw IPAError.unsafeArchive("archive entry metadata changed after preflight")
                }

                let destination = try policy.destinationURL(for: normalized, inside: extractionRoot)
                let resolvedParent = destination.deletingLastPathComponent().resolvingSymlinksInPath()
                guard policy.contains(resolvedParent.appending(path: destination.lastPathComponent), inside: extractionRoot) else {
                    throw IPAError.unsafeArchive("archive destination escaped its workspace")
                }

                let checksum = try archive.extract(entry, to: destination, skipCRC32: false)
                guard checksum == entry.checksum else {
                    throw IPAError.inspectionFailure
                }
                let values = try destination.resourceValues(forKeys: [
                    .isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey,
                ])
                guard values.isSymbolicLink != true else {
                    throw IPAError.unsafeArchive("archive created a symbolic link")
                }
                switch descriptor.kind {
                case .file:
                    guard values.isRegularFile == true,
                          let size = values.fileSize,
                          size >= 0,
                          UInt64(size) == descriptor.uncompressedSize
                    else {
                        throw IPAError.unsafeArchive("archive entry size did not match its declaration")
                    }
                    let (newTotal, overflow) = actualTotal.addingReportingOverflow(UInt64(size))
                    guard !overflow, newTotal <= policy.maximumTotalUncompressedBytes else {
                        throw IPAError.archiveTooLarge(maximumBytes: policy.maximumTotalUncompressedBytes)
                    }
                    actualTotal = newTotal
                    try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
                case .directory:
                    guard values.isDirectory == true else {
                        throw IPAError.unsafeArchive("archive directory could not be verified")
                    }
                    try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: destination.path)
                case .symbolicLink:
                    throw IPAError.unsafeArchive("symbolic links are not accepted")
                }

                let resolvedDestination = destination.resolvingSymlinksInPath()
                guard policy.contains(resolvedDestination, inside: extractionRoot.resolvingSymlinksInPath()) else {
                    throw IPAError.unsafeArchive("archive destination escaped its workspace")
                }
            }
        } catch let error as IPAError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw IPAError.inspectionFailure
        }

        guard extracted.count == preflight.entries.count else {
            throw IPAError.inspectionFailure
        }
    }

    private func archiveKind(for type: Entry.EntryType) -> ArchiveEntryKind {
        switch type {
        case .file: .file
        case .directory: .directory
        case .symlink: .symbolicLink
        }
    }
}
