import Foundation
import IPADomain

public protocol SigningService: Sendable {
    func sign(plan: SigningPlan, sourceIPA: URL, destination: URL) async throws -> SignedArtifact
}

public struct UnavailableSigningService: SigningService {
    public init() {}
    public func sign(plan: SigningPlan, sourceIPA: URL, destination: URL) async throws -> SignedArtifact {
        throw IPAError.unsupported("embedded signing engine integration is not implemented")
    }
}
