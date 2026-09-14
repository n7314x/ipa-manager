import Foundation

final class IPAExtractionWorkspace {
    static let prefix = "inspection-"

    let url: URL
    let extractionRoot: URL
    private let fileManager: FileManager

    init(parent: URL, fileManager: FileManager) throws {
        self.fileManager = fileManager
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        try Self.removeStaleWorkspaces(in: parent, fileManager: fileManager)

        url = parent.appending(
            path: Self.prefix + UUID().uuidString,
            directoryHint: .isDirectory
        )
        extractionRoot = url.appending(path: "extracted", directoryHint: .isDirectory)
        do {
            try fileManager.createDirectory(at: extractionRoot, withIntermediateDirectories: true)
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: extractionRoot.path)
        } catch {
            try? fileManager.removeItem(at: url)
            throw error
        }
    }

    func remove() {
        try? fileManager.removeItem(at: url)
    }

    deinit {
        remove()
    }

    private static func removeStaleWorkspaces(in parent: URL, fileManager: FileManager) throws {
        let children = try fileManager.contentsOfDirectory(
            at: parent,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        )
        for child in children where child.lastPathComponent.hasPrefix(prefix) {
            try fileManager.removeItem(at: child)
        }
    }
}
