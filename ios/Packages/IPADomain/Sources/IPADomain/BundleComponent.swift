import Foundation

public struct BundleComponent: Codable, Hashable, Identifiable, Sendable {
    public enum Kind: String, Codable, Sendable { case application, extensionBundle, framework, dylib }

    public let id: UUID
    public let kind: Kind
    public let relativePath: String
    public let bundleIdentifier: String?
    public let executableRelativePath: String?
    public var childIDs: [UUID]

    public init(
        id: UUID = UUID(), kind: Kind, relativePath: String,
        bundleIdentifier: String? = nil, executableRelativePath: String? = nil,
        childIDs: [UUID] = []
    ) {
        self.id = id
        self.kind = kind
        self.relativePath = relativePath
        self.bundleIdentifier = bundleIdentifier
        self.executableRelativePath = executableRelativePath
        self.childIDs = childIDs
    }
}
