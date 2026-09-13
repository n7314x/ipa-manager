import Foundation

public protocol IconExtracting: Sendable {
    func primaryIconData(appAt url: URL) async throws -> Data?
}
