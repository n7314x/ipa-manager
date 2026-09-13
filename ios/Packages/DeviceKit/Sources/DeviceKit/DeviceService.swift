import IPADomain

public protocol DeviceService: Sendable {
    func knownDevices() async throws -> [DeviceRecord]
}

public struct UnavailableDeviceService: DeviceService {
    public init() {}
    public func knownDevices() async throws -> [DeviceRecord] {
        throw IPAError.unsupported("direct device services are not implemented; export for iLoader")
    }
}
