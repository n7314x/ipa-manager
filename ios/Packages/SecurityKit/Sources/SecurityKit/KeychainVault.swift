import Foundation

public enum KeychainVaultError: Error, Equatable, Sendable {
    case unavailable
    case unexpectedStatus(Int32)
}

/// Narrow boundary for future Security.framework-backed secret storage.
public protocol KeychainVault: Sendable {
    func store(_ data: Data, service: String, account: String) async throws -> Data
    func remove(persistentReference: Data) async throws
}
