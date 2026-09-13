import Foundation
import IPADomain

public protocol EntitlementsInspecting: Sendable {
    func inspect(executableAt url: URL) async throws -> EntitlementSnapshot
}
