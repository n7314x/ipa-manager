import Foundation
import IPADomain

public protocol InspectionStorageCapacityProviding: Sendable {
    func availableCapacity(forVolumeContaining url: URL) throws -> UInt64
}

public struct FoundationInspectionStorageCapacityProvider: InspectionStorageCapacityProviding {
    public init() {}

    public func availableCapacity(forVolumeContaining url: URL) throws -> UInt64 {
        let values = try url.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey,
        ])
        guard let capacity = values.volumeAvailableCapacityForImportantUsage,
              capacity >= 0
        else {
            throw IPAError.inspectionFailure
        }
        return UInt64(capacity)
    }
}

struct InspectionStorageCapacityGuard: Sendable {
    let policy: ArchiveSafetyPolicy
    let capacityProvider: any InspectionStorageCapacityProviding

    func requiredCapacity(for declaredUncompressedBytes: UInt64) throws -> UInt64 {
        let (required, overflow) = declaredUncompressedBytes.addingReportingOverflow(
            policy.inspectionStorageSafetyReserveBytes
        )
        guard !overflow else {
            throw IPAError.insufficientStorage(requiredBytes: .max)
        }
        return required
    }

    func validate(
        declaredUncompressedBytes: UInt64,
        workspaceURL: URL
    ) throws {
        let required = try requiredCapacity(for: declaredUncompressedBytes)
        let available: UInt64
        do {
            available = try capacityProvider.availableCapacity(forVolumeContaining: workspaceURL)
        } catch {
            throw IPAError.insufficientStorage(requiredBytes: required)
        }
        guard available >= required else {
            throw IPAError.insufficientStorage(requiredBytes: required)
        }
    }
}
