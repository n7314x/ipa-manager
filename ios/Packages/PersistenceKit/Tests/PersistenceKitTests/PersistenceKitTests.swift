import Foundation
import IPADomain
import XCTest
@testable import PersistenceKit

@MainActor
final class PersistenceKitTests: XCTestCase {
    func testInMemoryContainerCanBeCreated() throws {
        _ = try PersistenceController(inMemory: true)
    }

    func testImportedIPAEntityDomainRoundTrip() {
        let expected = makeImportedIPA()
        let entity = ImportedIPAEntity(importedIPA: expected)

        XCTAssertEqual(entity.domainModel, expected)
    }

    func testPersistenceRetrievalAndDuplicateHashLookup() async throws {
        let controller = try PersistenceController(inMemory: true)
        let store = controller.makeImportedIPAStore()
        let expected = makeImportedIPA()

        try await store.save(expected)

        let items = try await store.listImportedIPAs()
        XCTAssertEqual(items, [expected])
        let foundByID = try await store.importedIPA(id: expected.id)
        XCTAssertEqual(foundByID, expected)
        let foundByHash = try await store.findBySHA256(expected.sourceSHA256)
        XCTAssertEqual(foundByHash, expected)
    }

    func testDeletion() async throws {
        let controller = try PersistenceController(inMemory: true)
        let store = controller.makeImportedIPAStore()
        let expected = makeImportedIPA()
        try await store.save(expected)

        try await store.removeImportedIPA(id: expected.id)

        let deleted = try await store.importedIPA(id: expected.id)
        XCTAssertNil(deleted)
        let remaining = try await store.listImportedIPAs()
        XCTAssertTrue(remaining.isEmpty)
    }

    func testInspectionMetadataAndComponentsSurviveStoreRoundTrip() async throws {
        let controller = try PersistenceController(inMemory: true)
        let store = controller.makeImportedIPAStore()
        let imported = makeImportedIPA()
        let result = makeInspectionResult(for: imported)
        try await store.save(imported)

        try await store.updateInspection(
            id: imported.id,
            status: .inspected,
            sourceSHA256: imported.sourceSHA256,
            result: result
        )

        let restored = try await store.importedIPA(id: imported.id)
        XCTAssertEqual(restored?.inspectionStatus, .inspected)
        XCTAssertEqual(restored?.inspectionSourceSHA256, imported.sourceSHA256)
        XCTAssertEqual(restored?.inspection, result)
        XCTAssertFalse(restored?.needsInspection ?? true)
    }

    func testFailedInspectionStateSurvivesWithoutDerivedPayload() async throws {
        let controller = try PersistenceController(inMemory: true)
        let store = controller.makeImportedIPAStore()
        let imported = makeImportedIPA()
        try await store.save(imported)

        try await store.updateInspection(
            id: imported.id,
            status: .failed(.unsafeArchive),
            sourceSHA256: imported.sourceSHA256,
            result: nil
        )

        let restored = try await store.importedIPA(id: imported.id)
        XCTAssertEqual(restored?.inspectionStatus, .failed(.unsafeArchive))
        XCTAssertNil(restored?.inspection)
        XCTAssertFalse(restored?.needsInspection ?? true)
    }

    private func makeImportedIPA() -> ImportedIPA {
        ImportedIPA(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            originalFilename: "Synthetic.ipa",
            sourceSHA256: String(repeating: "a", count: 64),
            originalRelativePath: "Library/11111111-2222-3333-4444-555555555555/original.ipa",
            byteSize: 1_024,
            importedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    private func makeInspectionResult(for importedIPA: ImportedIPA) -> IPAInspectionResult {
        let extensionComponent = BundleComponent(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
            kind: .extensionBundle,
            relativePath: "Payload/Synthetic.app/PlugIns/Widget.appex",
            bundleIdentifier: "example.synthetic.widget",
            displayName: "Widget",
            version: "1.2.3",
            buildVersion: "45"
        )
        let mainComponent = BundleComponent(
            id: UUID(uuidString: "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF") ?? UUID(),
            kind: .application,
            relativePath: "Payload/Synthetic.app",
            bundleIdentifier: "example.synthetic",
            displayName: "Synthetic",
            version: "1.2.3",
            buildVersion: "45",
            childIDs: [extensionComponent.id]
        )
        return IPAInspectionResult(
            importedIPAID: importedIPA.id,
            sourceSHA256: importedIPA.sourceSHA256,
            rootApplication: AppBundleMetadata(
                displayName: "Synthetic",
                bundleName: "Synthetic",
                bundleIdentifier: "example.synthetic",
                shortVersion: "1.2.3",
                buildVersion: "45",
                executableName: "Synthetic",
                minimumOSVersion: "17.0",
                deviceFamilies: [1, 2],
                packageType: "APPL",
                platformName: "iphoneos",
                platformVersion: "26.0",
                sdkName: "iphoneos26.0",
                relativePath: "Payload/Synthetic.app",
                icon: AppIconMetadata(
                    relativePath: "Library/id/metadata/app-icon.png",
                    pixelWidth: 180,
                    pixelHeight: 180,
                    byteSize: 512
                )
            ),
            components: [mainComponent, extensionComponent],
            provisioningProfile: ProvisioningProfileMetadata(
                relativePath: "Payload/Synthetic.app/embedded.mobileprovision",
                decodeStatus: .decoded,
                profileUUID: "PROFILE-UUID",
                name: "Development",
                teamIdentifiers: ["TEAMID"],
                teamName: "Example Team",
                applicationIdentifierPrefixes: ["TEAMID"],
                expirationDate: Date(timeIntervalSince1970: 1_800_000_000),
                creationDate: Date(timeIntervalSince1970: 1_700_000_000),
                provisionedDevicesCount: 2,
                provisionsAllDevices: false,
                entitlements: ["get-task-allow": .boolean(true)]
            ),
            inspectedAt: Date(timeIntervalSince1970: 1_750_000_000)
        )
    }
}
