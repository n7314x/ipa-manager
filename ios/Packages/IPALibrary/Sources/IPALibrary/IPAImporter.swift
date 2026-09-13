import Foundation
import IPADomain

public struct IPAImporter: Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Copies the provider URL into an app-owned temporary workspace and releases it immediately.
    public func copyToTemporaryWorkspace(from source: URL, to destination: URL) throws {
        let accessed = source.startAccessingSecurityScopedResource()
        defer { if accessed { source.stopAccessingSecurityScopedResource() } }

        do {
            guard source.pathExtension.lowercased() == "ipa" else {
                throw IPAError.invalidSource("the filename does not have an .ipa extension")
            }
            let values = try source.resourceValues(forKeys: [
                .isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey,
            ])
            guard values.isRegularFile == true, values.isDirectory != true, values.isSymbolicLink != true else {
                throw IPAError.invalidSource("the selection is not a regular file")
            }
            guard !fileManager.fileExists(atPath: destination.path) else {
                throw IPAError.storageFailure("the temporary destination already exists")
            }
            try fileManager.copyItem(at: source, to: destination)
        } catch let error as IPAError {
            throw error
        } catch {
            try? fileManager.removeItem(at: destination)
            throw IPAError.inaccessibleSource
        }
    }
}
