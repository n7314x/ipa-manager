import Foundation
import SwiftData

@Model
public final class SigningIdentityEntity {
    @Attribute(.unique) public var id: UUID
    public var commonName: String
    @Attribute(.unique) public var certificateSHA256: String
    public var expiresAt: Date
    public var keychainPersistentReference: Data

    public init(id: UUID, commonName: String, certificateSHA256: String, expiresAt: Date, keychainPersistentReference: Data) {
        self.id = id
        self.commonName = commonName
        self.certificateSHA256 = certificateSHA256
        self.expiresAt = expiresAt
        self.keychainPersistentReference = keychainPersistentReference
    }
}
