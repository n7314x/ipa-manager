import Foundation

public final class SecretBuffer: @unchecked Sendable {
    private var storage: Data
    private let lock = NSLock()

    public init(_ data: Data) { storage = data }
    deinit { clear() }

    public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try storage.withUnsafeBytes(body)
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        storage.resetBytes(in: storage.startIndex..<storage.endIndex)
        storage.removeAll(keepingCapacity: false)
    }
}
