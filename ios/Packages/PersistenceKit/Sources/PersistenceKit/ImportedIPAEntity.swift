import Foundation
import SwiftData

@Model
public final class ImportedIPAEntity {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var sourceSHA256: String
    public var originalRelativePath: String
    public var importedAt: Date

    public init(id: UUID, sourceSHA256: String, originalRelativePath: String, importedAt: Date) {
        self.id = id
        self.sourceSHA256 = sourceSHA256
        self.originalRelativePath = originalRelativePath
        self.importedAt = importedAt
    }
}
