import Foundation
import SwiftData

@MainActor
public final class PersistenceController {
    public let container: ModelContainer

    public init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(
            for: ImportedIPAEntity.self, SignedArtifactEntity.self, AuditEventEntity.self,
            InstallationRecordEntity.self, ProvisioningProfileEntity.self, SigningIdentityEntity.self,
            configurations: configuration
        )
    }
}
