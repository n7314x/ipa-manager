import Foundation
import IPADomain

public struct IPAImporter: Sendable {
    public init() {}

    /// Copies a security-scoped import into app-owned storage. Callers validate and hash the copy.
    public func copyOriginal(from source: URL, to destination: URL) throws {
        let accessed = source.startAccessingSecurityScopedResource()
        defer { if accessed { source.stopAccessingSecurityScopedResource() } }
        guard source.pathExtension.lowercased() == "ipa" else { throw IPAError.invalidArchive("file is not an IPA") }
        let values = try source.resourceValues(forKeys: [.isRegularFileKey])
        guard values.isRegularFile == true else { throw IPAError.invalidArchive("IPA source is not a regular file") }
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard !FileManager.default.fileExists(atPath: destination.path) else { throw IPAError.invalidArchive("original IPA already exists") }
        let temporary = destination.deletingLastPathComponent().appending(path: ".importing-(UUID().uuidString)")
        do {
            try FileManager.default.copyItem(at: source, to: temporary)
            try FileManager.default.setAttributes([.posixPermissions: 0o400], ofItemAtPath: temporary.path)
            try FileManager.default.moveItem(at: temporary, to: destination)
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
    }
}
