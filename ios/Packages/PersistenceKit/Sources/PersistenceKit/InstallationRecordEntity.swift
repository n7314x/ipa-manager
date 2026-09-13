import Foundation
import SwiftData

@Model
public final class InstallationRecordEntity {
    @Attribute(.unique) public var id: UUID
    public var artifactID: UUID
    public var deviceID: UUID
    public var status: String
    public var installedAt: Date?
    public var confirmedExpiry: Date?

    public init(id: UUID, artifactID: UUID, deviceID: UUID, status: String) {
        self.id = id
        self.artifactID = artifactID
        self.deviceID = deviceID
        self.status = status
    }
}
