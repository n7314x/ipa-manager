import Foundation

public struct AppBundle: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let bundleIdentifier: String
    public let displayName: String
    public let version: String
    public let buildVersion: String
    public let relativePath: String
    public var components: [BundleComponent]

    public init(
        id: UUID = UUID(), bundleIdentifier: String, displayName: String,
        version: String, buildVersion: String, relativePath: String,
        components: [BundleComponent] = []
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.version = version
        self.buildVersion = buildVersion
        self.relativePath = relativePath
        self.components = components
    }
}
