import Foundation

public struct AuditEvent: Codable, Hashable, Identifiable, Sendable {
    public enum Kind: String, Codable, Sendable { case imported, inspected, signingPlanned, signed, installed, refreshVerified, failed }

    public let id: UUID
    public let occurredAt: Date
    public let kind: Kind
    public let subjectID: UUID?
    public let summary: String

    public init(id: UUID = UUID(), occurredAt: Date = Date(), kind: Kind, subjectID: UUID? = nil, summary: String) {
        self.id = id
        self.occurredAt = occurredAt
        self.kind = kind
        self.subjectID = subjectID
        self.summary = summary
    }
}
