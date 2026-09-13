import Foundation
import IPADomain

public struct ArchiveEntryDescriptor: Hashable, Sendable {
    public let path: String
    public let compressedSize: UInt64
    public let uncompressedSize: UInt64
    public let isSymbolicLink: Bool

    public init(path: String, compressedSize: UInt64, uncompressedSize: UInt64, isSymbolicLink: Bool = false) {
        self.path = path
        self.compressedSize = compressedSize
        self.uncompressedSize = uncompressedSize
        self.isSymbolicLink = isSymbolicLink
    }
}

public struct ArchiveSafetyPolicy: Hashable, Sendable {
    public var maximumEntryCount: Int
    public var maximumTotalUncompressedBytes: UInt64
    public var maximumEntryUncompressedBytes: UInt64
    public var maximumCompressionRatio: UInt64

    public init(
        maximumEntryCount: Int = 10_000,
        maximumTotalUncompressedBytes: UInt64 = 8 * 1_024 * 1_024 * 1_024,
        maximumEntryUncompressedBytes: UInt64 = 512 * 1_024 * 1_024,
        maximumCompressionRatio: UInt64 = 200
    ) {
        self.maximumEntryCount = maximumEntryCount
        self.maximumTotalUncompressedBytes = maximumTotalUncompressedBytes
        self.maximumEntryUncompressedBytes = maximumEntryUncompressedBytes
        self.maximumCompressionRatio = maximumCompressionRatio
    }

    public static let `default` = ArchiveSafetyPolicy()

    public func validate(_ entries: [ArchiveEntryDescriptor]) throws {
        guard entries.count <= maximumEntryCount else { throw IPAError.unsafeArchive("entry limit exceeded") }
        var seen = Set<String>()
        var total: UInt64 = 0
        for entry in entries {
            let normalized = try normalizedPath(entry.path)
            guard seen.insert(normalized).inserted else { throw IPAError.unsafeArchive("duplicate archive path") }
            guard !entry.isSymbolicLink else { throw IPAError.unsafeArchive("symbolic links are not accepted") }
            guard entry.uncompressedSize <= maximumEntryUncompressedBytes else { throw IPAError.unsafeArchive("entry size limit exceeded") }
            let (newTotal, overflow) = total.addingReportingOverflow(entry.uncompressedSize)
            guard !overflow, newTotal <= maximumTotalUncompressedBytes else { throw IPAError.unsafeArchive("archive size limit exceeded") }
            total = newTotal
            if entry.compressedSize == 0 {
                guard entry.uncompressedSize == 0 else { throw IPAError.unsafeArchive("invalid compression metadata") }
            } else {
                let (allowedSize, overflow) = entry.compressedSize.multipliedReportingOverflow(by: maximumCompressionRatio)
                guard overflow || entry.uncompressedSize <= allowedSize else {
                    throw IPAError.unsafeArchive("compression ratio limit exceeded")
                }
            }
        }
    }

    public func normalizedPath(_ path: String) throws -> String {
        guard !path.isEmpty, !path.hasPrefix("/"), !path.contains("\\"), !path.contains("\0") else {
            throw IPAError.unsafeArchive("invalid archive path")
        }
        let pathWithoutDirectoryMarker = path.hasSuffix("/") ? String(path.dropLast()) : path
        let parts = pathWithoutDirectoryMarker.split(separator: "/", omittingEmptySubsequences: false)
        guard !parts.contains(where: { $0 == "." || $0 == ".." || $0.isEmpty }) else {
            throw IPAError.unsafeArchive("archive path traversal")
        }
        return pathWithoutDirectoryMarker.precomposedStringWithCanonicalMapping
    }
}
