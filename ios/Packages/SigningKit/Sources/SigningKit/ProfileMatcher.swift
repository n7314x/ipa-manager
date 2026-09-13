import IPADomain

public struct ProfileMatcher: Sendable {
    public init() {}

    public func profile(_ profile: ProvisioningProfile, authorizes bundleIdentifier: String) -> Bool {
        let components = profile.applicationIdentifier.split(separator: ".", maxSplits: 1)
        guard components.count == 2 else { return false }
        let pattern = String(components[1])
        if pattern == "*" { return true }
        if pattern.hasSuffix(".*") { return bundleIdentifier.hasPrefix(String(pattern.dropLast())) }
        return pattern == bundleIdentifier
    }
}
