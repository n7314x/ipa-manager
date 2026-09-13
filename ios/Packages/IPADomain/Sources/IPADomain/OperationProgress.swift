public struct OperationProgress: Codable, Hashable, Sendable {
    public enum Phase: String, Codable, Sendable { case preparing, validating, inspecting, signing, installing, verifying }

    public let phase: Phase
    public let completedUnits: Int64
    public let totalUnits: Int64?
    public let message: String

    public init(phase: Phase, completedUnits: Int64 = 0, totalUnits: Int64? = nil, message: String) {
        self.phase = phase
        self.completedUnits = completedUnits
        self.totalUnits = totalUnits
        self.message = message
    }
}
