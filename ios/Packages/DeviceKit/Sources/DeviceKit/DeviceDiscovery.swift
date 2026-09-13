import IPADomain

public protocol DeviceDiscovery: Sendable {
    func discover() async throws -> [DeviceRecord]
}
