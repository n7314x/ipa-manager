import Foundation
import SwiftData

@Model
public final class SignedArtifactEntity {
    @Attribute(.unique) public var id: UUID
    public var sourceIPAID: UUID
    @Attribute(.unique) public var artifactSHA256: String
    public var relativePath: String
    public var createdAt: Date

    public init(id: UUID, sourceIPAID: UUID, artifactSHA256: String, relativePath: String, createdAt: Date) {
        self.id = id
        self.sourceIPAID = sourceIPAID
        self.artifactSHA256 = artifactSHA256
        self.relativePath = relativePath
        self.createdAt = createdAt
    }
}
