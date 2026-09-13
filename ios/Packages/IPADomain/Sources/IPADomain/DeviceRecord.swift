import Foundation

public struct DeviceRecord: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let deviceIdentifier: String
    public var displayName: String
    public var productVersion: String?
    public var lastSeenAt: Date?

    public init(id: UUID = UUID(), deviceIdentifier: String, displayName: String, productVersion: String? = nil, lastSeenAt: Date? = nil) {
        self.id = id
        self.deviceIdentifier = deviceIdentifier
        self.displayName = displayName
        self.productVersion = productVersion
        self.lastSeenAt = lastSeenAt
    }
}
