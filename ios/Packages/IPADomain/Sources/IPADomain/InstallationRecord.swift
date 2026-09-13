import Foundation

public struct InstallationRecord: Codable, Hashable, Identifiable, Sendable {
    public enum Status: String, Codable, Sendable { case pending, installing, installed, failed }

    public let id: UUID
    public let artifactID: UUID
    public let deviceID: UUID
    public var status: Status
    public var installedAt: Date?
    public var confirmedExpiry: Date?

    public init(id: UUID = UUID(), artifactID: UUID, deviceID: UUID, status: Status = .pending, installedAt: Date? = nil, confirmedExpiry: Date? = nil) {
        self.id = id
        self.artifactID = artifactID
        self.deviceID = deviceID
        self.status = status
        self.installedAt = installedAt
        self.confirmedExpiry = confirmedExpiry
    }
}
