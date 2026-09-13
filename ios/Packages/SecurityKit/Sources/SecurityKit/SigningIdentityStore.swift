import Foundation

public protocol SigningIdentityStore: Sendable {
    /// Imports PKCS#12 data into Keychain. Passwords must never be persisted or logged.
    func importPKCS12(_ data: Data, password: SecretBuffer) async throws -> Data
    func removeIdentity(persistentReference: Data) async throws
}
