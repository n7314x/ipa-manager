public struct EntitlementSnapshot: Codable, Hashable, Sendable {
    public let values: [String: String]

    public init(values: [String: String] = [:]) { self.values = values }
}
