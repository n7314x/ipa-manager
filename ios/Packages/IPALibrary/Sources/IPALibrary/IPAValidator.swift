import Foundation
import IPADomain
import ZIPFoundation

public struct IPAValidator: Sendable {
    public init() {}

    public func validateSource(at url: URL, policy: ArchiveSafetyPolicy = .default) throws -> Int64 {
        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: [
                .fileSizeKey, .isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey,
            ])
        } catch {
            throw IPAError.invalidSource("the copied file cannot be read")
        }
        guard values.isRegularFile == true, values.isDirectory != true, values.isSymbolicLink != true else {
            throw IPAError.invalidSource("the selection is not a regular file")
        }
        guard let fileSize = values.fileSize, fileSize > 0 else {
            throw IPAError.invalidSource("the file is empty")
        }
        guard UInt64(fileSize) <= policy.maximumSourceIPABytes else {
            throw IPAError.sourceTooLarge(maximumBytes: policy.maximumSourceIPABytes)
        }

        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw IPAError.unsupportedArchive
        }

        var entries: [ArchiveEntryDescriptor] = []
        var paths: [String] = []
        entries.reserveCapacity(min(policy.maximumEntryCount, 256))
        paths.reserveCapacity(min(policy.maximumEntryCount, 256))
        for entry in archive {
            guard entries.count < policy.maximumEntryCount else {
                throw IPAError.unsafeArchive("entry limit exceeded")
            }
            entries.append(ArchiveEntryDescriptor(
                path: entry.path,
                compressedSize: entry.compressedSize,
                uncompressedSize: entry.uncompressedSize,
                isSymbolicLink: entry.type == .symlink
            ))
            paths.append(entry.path)
        }
        guard !entries.isEmpty else { throw IPAError.unsupportedArchive }
        try policy.validate(entries)
        _ = try validatePayloadPaths(paths)
        return Int64(fileSize)
    }

    public func validatePayloadPaths(_ paths: [String]) throws -> String {
        let apps = Set(paths.compactMap { path -> String? in
            let parts = path.split(separator: "/")
            guard parts.count >= 2, parts[0] == "Payload", parts[1].hasSuffix(".app") else { return nil }
            return "Payload/\(parts[1])"
        })
        guard apps.count == 1, let app = apps.first else {
            throw IPAError.invalidArchive("expected exactly one top-level Payload app")
        }
        return app
    }
}
