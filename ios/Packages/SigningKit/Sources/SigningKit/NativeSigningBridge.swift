import IPADomain

public enum NativeSigningBridge {
    public static let isAvailable = false
    public static func requireAvailable() throws {
        throw IPAError.unsupported("native signer is not linked")
    }
}
