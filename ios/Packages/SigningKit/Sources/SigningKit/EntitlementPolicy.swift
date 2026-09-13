import IPADomain

public struct EntitlementPolicy: Sendable {
    public let allowedKeys: Set<String>
    public init(allowedKeys: Set<String>) { self.allowedKeys = allowedKeys }

    public func effective(original: EntitlementSnapshot, authorized: EntitlementSnapshot) -> EntitlementSnapshot {
        let values = original.values.filter { key, value in
            allowedKeys.contains(key) && authorized.values[key] == value
        }
        return EntitlementSnapshot(values: values)
    }
}
