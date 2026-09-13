import Foundation
import IPADomain
import SwiftData

@Model
public final class ImportedIPAEntity {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var sourceSHA256: String
    public var originalFilename: String = ""
    public var originalRelativePath: String
    public var byteSize: Int64 = 0
    public var importedAt: Date

    public init(
        id: UUID,
        originalFilename: String,
        sourceSHA256: String,
        originalRelativePath: String,
        byteSize: Int64,
        importedAt: Date
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.sourceSHA256 = sourceSHA256
        self.originalRelativePath = originalRelativePath
        self.byteSize = byteSize
        self.importedAt = importedAt
    }

    public convenience init(importedIPA: ImportedIPA) {
        self.init(
            id: importedIPA.id,
            originalFilename: importedIPA.originalFilename,
            sourceSHA256: importedIPA.sourceSHA256,
            originalRelativePath: importedIPA.originalRelativePath,
            byteSize: importedIPA.byteSize,
            importedAt: importedIPA.importedAt
        )
    }

    public var domainModel: ImportedIPA {
        ImportedIPA(
            id: id,
            originalFilename: originalFilename,
            sourceSHA256: sourceSHA256,
            originalRelativePath: originalRelativePath,
            byteSize: byteSize,
            importedAt: importedAt
        )
    }
}
