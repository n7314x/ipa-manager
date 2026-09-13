import Foundation

public struct LibraryFileLayout: Sendable {
    public let applicationSupportURL: URL

    public init(applicationSupportURL: URL) { self.applicationSupportURL = applicationSupportURL }

    public var libraryRoot: URL { applicationSupportURL.appending(path: "Library", directoryHint: .isDirectory) }
    public var temporaryWorkspaceRoot: URL {
        applicationSupportURL.appending(path: "Import Workspaces", directoryHint: .isDirectory)
    }

    public func root(for id: UUID) -> URL { libraryRoot.appending(path: id.uuidString, directoryHint: .isDirectory) }
    public func originalIPA(for id: UUID) -> URL { root(for: id).appending(path: "original.ipa") }
    public func metadataDirectory(for id: UUID) -> URL { root(for: id).appending(path: "metadata", directoryHint: .isDirectory) }
    public func artifactsDirectory(for id: UUID) -> URL { root(for: id).appending(path: "artifacts", directoryHint: .isDirectory) }
    public func workDirectory(for id: UUID) -> URL { root(for: id).appending(path: "work", directoryHint: .isDirectory) }

    public func originalRelativePath(for id: UUID) -> String { "Library/\(id.uuidString)/original.ipa" }

    public func createDirectories(for id: UUID, fileManager: FileManager = .default) throws {
        let managedRoot = root(for: id)
        guard !fileManager.fileExists(atPath: managedRoot.path) else {
            throw CocoaError(.fileWriteFileExists)
        }
        try fileManager.createDirectory(at: managedRoot, withIntermediateDirectories: false)
        do {
            try fileManager.createDirectory(at: metadataDirectory(for: id), withIntermediateDirectories: false)
            try fileManager.createDirectory(at: artifactsDirectory(for: id), withIntermediateDirectories: false)
            try fileManager.createDirectory(at: workDirectory(for: id), withIntermediateDirectories: false)
        } catch {
            try? fileManager.removeItem(at: managedRoot)
            throw error
        }
    }
}
