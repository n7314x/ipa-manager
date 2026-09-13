import Foundation

public struct ProvisioningProfile: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let profileUUID: String
    public let name: String
    public let applicationIdentifier: String
    public let teamIdentifiers: [String]
    public let expiresAt: Date
    public let authorizedEntitlements: EntitlementSnapshot
    public let relativePath: String

    public init(id: UUID = UUID(), profileUUID: String, name: String, applicationIdentifier: String, teamIdentifiers: [String], expiresAt: Date, authorizedEntitlements: EntitlementSnapshot, relativePath: String) {
        self.id = id
        self.profileUUID = profileUUID
        self.name = name
        self.applicationIdentifier = applicationIdentifier
        self.teamIdentifiers = teamIdentifiers
        self.expiresAt = expiresAt
        self.authorizedEntitlements = authorizedEntitlements
        self.relativePath = relativePath
    }
}
