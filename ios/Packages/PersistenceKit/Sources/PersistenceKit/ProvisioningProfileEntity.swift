import Foundation
import SwiftData

@Model
public final class ProvisioningProfileEntity {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var profileUUID: String
    public var name: String
    public var applicationIdentifier: String
    public var expiresAt: Date
    public var relativePath: String

    public init(id: UUID, profileUUID: String, name: String, applicationIdentifier: String, expiresAt: Date, relativePath: String) {
        self.id = id
        self.profileUUID = profileUUID
        self.name = name
        self.applicationIdentifier = applicationIdentifier
        self.expiresAt = expiresAt
        self.relativePath = relativePath
    }
}
