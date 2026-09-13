import Foundation

public struct LibraryFileLayout: Sendable {
    public let applicationSupportURL: URL

    public init(applicationSupportURL: URL) { self.applicationSupportURL = applicationSupportURL }

    public func root(for id: UUID) -> URL { applicationSupportURL.appending(path: "Library/\(id.uuidString)", directoryHint: .isDirectory) }
    public func originalIPA(for id: UUID) -> URL { root(for: id).appending(path: "original.ipa") }
    public func metadataDirectory(for id: UUID) -> URL { root(for: id).appending(path: "metadata", directoryHint: .isDirectory) }
    public func artifactsDirectory(for id: UUID) -> URL { root(for: id).appending(path: "artifacts", directoryHint: .isDirectory) }
    public func workDirectory(for id: UUID) -> URL { root(for: id).appending(path: "work", directoryHint: .isDirectory) }
}
