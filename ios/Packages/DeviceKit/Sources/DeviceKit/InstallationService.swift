import Foundation
import IPADomain

public protocol InstallationService: Sendable {
    func install(artifact: SignedArtifact, on device: DeviceRecord) async throws -> InstallationRecord
}
