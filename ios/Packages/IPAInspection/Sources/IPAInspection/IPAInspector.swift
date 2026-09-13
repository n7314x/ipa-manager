import Foundation
import IPADomain

public protocol IPAInspecting: Sendable {
    func inspect(appAt url: URL) async throws -> AppBundle
}

public struct UnavailableIPAInspector: IPAInspecting {
    public init() {}
    public func inspect(appAt url: URL) async throws -> AppBundle {
        throw IPAError.unsupported("full bundle inspection is not implemented")
    }
}
