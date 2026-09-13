public struct RefreshPolicy: Codable, Hashable, Sendable {
    public let enabled: Bool
    public let refreshBeforeExpiryDays: Int

    public init(enabled: Bool = false, refreshBeforeExpiryDays: Int = 2) {
        self.enabled = enabled
        self.refreshBeforeExpiryDays = refreshBeforeExpiryDays
    }
}
