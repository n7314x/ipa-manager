import Foundation

public struct SigningIdentity: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let commonName: String
    public let certificateSHA256: String
    public let expiresAt: Date
    public let keychainPersistentReference: Data

    public init(id: UUID = UUID(), commonName: String, certificateSHA256: String, expiresAt: Date, keychainPersistentReference: Data) {
        self.id = id
        self.commonName = commonName
        self.certificateSHA256 = certificateSHA256
        self.expiresAt = expiresAt
        self.keychainPersistentReference = keychainPersistentReference
    }
}
