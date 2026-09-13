import Foundation

public struct ImportedIPA: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let sourceSHA256: String
    public let originalRelativePath: String
    public let importedAt: Date
    public var app: AppBundle?

    public init(
        id: UUID = UUID(),
        sourceSHA256: String,
        originalRelativePath: String,
        importedAt: Date = Date(),
        app: AppBundle? = nil
    ) {
        self.id = id
        self.sourceSHA256 = sourceSHA256
        self.originalRelativePath = originalRelativePath
        self.importedAt = importedAt
        self.app = app
    }
}
