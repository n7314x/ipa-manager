import Foundation

public struct ImportedIPA: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let originalFilename: String
    public let sourceSHA256: String
    public let originalRelativePath: String
    public let byteSize: Int64
    public let importedAt: Date
    public var app: AppBundle?

    public init(
        id: UUID = UUID(),
        originalFilename: String,
        sourceSHA256: String,
        originalRelativePath: String,
        byteSize: Int64,
        importedAt: Date = Date(),
        app: AppBundle? = nil
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.sourceSHA256 = sourceSHA256
        self.originalRelativePath = originalRelativePath
        self.byteSize = byteSize
        self.importedAt = importedAt
        self.app = app
    }
}
