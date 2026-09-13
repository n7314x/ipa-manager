import Foundation
import IPADomain

public protocol SigningPlanning: Sendable {
    func makePlan(for importedIPA: ImportedIPA, identity: SigningIdentity, profiles: [ProvisioningProfile]) throws -> SigningPlan
}
