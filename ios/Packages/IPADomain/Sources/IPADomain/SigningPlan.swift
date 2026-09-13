import Foundation

public struct SigningPlan: Codable, Hashable, Identifiable, Sendable {
    public struct Step: Codable, Hashable, Sendable {
        public let componentID: UUID
        public let provisioningProfileID: UUID?
        public let effectiveEntitlements: EntitlementSnapshot

        public init(componentID: UUID, provisioningProfileID: UUID?, effectiveEntitlements: EntitlementSnapshot) {
            self.componentID = componentID
            self.provisioningProfileID = provisioningProfileID
            self.effectiveEntitlements = effectiveEntitlements
        }
    }

    public let id: UUID
    public let sourceIPAID: UUID
    public let identityID: UUID
    public let stepsInSigningOrder: [Step]

    public init(id: UUID = UUID(), sourceIPAID: UUID, identityID: UUID, stepsInSigningOrder: [Step]) {
        self.id = id
        self.sourceIPAID = sourceIPAID
        self.identityID = identityID
        self.stepsInSigningOrder = stepsInSigningOrder
    }
}
