import Foundation
import IPADomain

public protocol ProvisioningInspecting: Sendable {
    func inspect(profileAt url: URL) async throws -> ProvisioningProfile
}
