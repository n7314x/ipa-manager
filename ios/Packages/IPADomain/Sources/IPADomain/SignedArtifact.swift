import Foundation

public struct SignedArtifact: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let sourceIPAID: UUID
    public let sourceSHA256: String
    public let artifactSHA256: String
    public let relativePath: String
    public let createdAt: Date
    public let expiresAt: Date?

    public init(id: UUID = UUID(), sourceIPAID: UUID, sourceSHA256: String, artifactSHA256: String, relativePath: String, createdAt: Date = Date(), expiresAt: Date? = nil) {
        self.id = id
        self.sourceIPAID = sourceIPAID
        self.sourceSHA256 = sourceSHA256
        self.artifactSHA256 = artifactSHA256
        self.relativePath = relativePath
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}
