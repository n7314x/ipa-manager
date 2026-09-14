import Foundation

public struct BundleComponent: Codable, Hashable, Identifiable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case application
        case extensionBundle
        case framework
        case nestedApplication
        case dylib
    }

    public let id: UUID
    public let kind: Kind
    public let relativePath: String
    public let bundleIdentifier: String?
    public let displayName: String?
    public let version: String?
    public let buildVersion: String?
    public let executableRelativePath: String?
    public var childIDs: [UUID]

    public init(
        id: UUID = UUID(), kind: Kind, relativePath: String,
        bundleIdentifier: String? = nil, displayName: String? = nil,
        version: String? = nil, buildVersion: String? = nil,
        executableRelativePath: String? = nil,
        childIDs: [UUID] = []
    ) {
        self.id = id
        self.kind = kind
        self.relativePath = relativePath
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.version = version
        self.buildVersion = buildVersion
        self.executableRelativePath = executableRelativePath
        self.childIDs = childIDs
    }
}
