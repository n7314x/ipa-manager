import Foundation

public final class TemporaryWorkspace {
    public let url: URL
    private let fileManager: FileManager

    public init(parent: URL, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        self.url = parent.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit { try? fileManager.removeItem(at: url) }
}
