import Foundation

public struct SecureFileStore: Sendable {
    public init() {}
    public func write(_ data: Data, to url: URL) throws {
#if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
#else
        try data.write(to: url, options: [.atomic])
#endif
    }
}
