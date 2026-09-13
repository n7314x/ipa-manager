import IPADomain

public protocol PairingService: Sendable {
    func pair(device: DeviceRecord) async throws
    func unpair(device: DeviceRecord) async throws
}
