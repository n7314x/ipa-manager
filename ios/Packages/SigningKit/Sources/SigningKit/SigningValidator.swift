public struct SigningCompatibility: Equatable, Sendable {
    public let issues: [String]
    public var isCompatible: Bool { issues.isEmpty }
    public init(issues: [String] = []) { self.issues = issues }
}

public struct SigningValidator: Sendable {
    public init() {}
    public func validate(stepCount: Int) -> SigningCompatibility {
        stepCount > 0 ? SigningCompatibility() : SigningCompatibility(issues: ["signing plan is empty"])
    }
}
