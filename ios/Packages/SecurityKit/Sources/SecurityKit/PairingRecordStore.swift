import Foundation

public protocol PairingRecordStore: Sendable {
    func storeEncryptedRecord(_ record: Data, deviceIdentifier: String) async throws
    func encryptedRecord(deviceIdentifier: String) async throws -> Data?
    func removeRecord(deviceIdentifier: String) async throws
}
