import Foundation
import SwiftData

@Model
public final class AuditEventEntity {
    @Attribute(.unique) public var id: UUID
    public var occurredAt: Date
    public var kind: String
    public var subjectID: UUID?
    public var summary: String

    public init(id: UUID, occurredAt: Date, kind: String, subjectID: UUID?, summary: String) {
        self.id = id
        self.occurredAt = occurredAt
        self.kind = kind
        self.subjectID = subjectID
        self.summary = summary
    }
}
