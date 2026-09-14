import XCTest
@testable import IPADomain

final class IPADomainTests: XCTestCase {
    func testIPAFileSelectionAcceptsIPAExtensionCaseInsensitively() {
        for filename in ["App.ipa", "app.IPA"] {
            XCTAssertNoThrow(try IPAFileSelection.validate(URL(fileURLWithPath: filename)))
        }
    }

    func testIPAFileSelectionRejectsNonIPAExtensions() {
        for filename in ["something.zip", "something.txt", "ipa-without-extension"] {
            XCTAssertThrowsError(try IPAFileSelection.validate(URL(fileURLWithPath: filename))) { error in
                XCTAssertEqual(error as? IPAError, .invalidFileExtension)
            }
        }
    }

    func testImportedIPAKeepsSourceHash() {
        let imported = ImportedIPA(
            originalFilename: "Example.ipa",
            sourceSHA256: "abc123",
            originalRelativePath: "Library/id/original.ipa",
            byteSize: 42
        )
        XCTAssertEqual(imported.sourceSHA256, "abc123")
        XCTAssertEqual(imported.originalFilename, "Example.ipa")
        XCTAssertEqual(imported.byteSize, 42)
    }

    func testInspectionCacheMustMatchSourceHashAndFormat() {
        let identifier = UUID()
        let hash = "abc123"
        let result = IPAInspectionResult(
            importedIPAID: identifier,
            sourceSHA256: hash,
            rootApplication: AppBundleMetadata(
                displayName: "Example",
                relativePath: "Payload/Example.app"
            ),
            components: [],
            provisioningProfile: nil
        )
        let cached = ImportedIPA(
            id: identifier,
            originalFilename: "Example.ipa",
            sourceSHA256: hash,
            originalRelativePath: "Library/id/original.ipa",
            byteSize: 42,
            inspectionStatus: .inspected,
            inspectionSourceSHA256: hash,
            inspection: result
        )
        XCTAssertFalse(cached.needsInspection)

        var mismatched = cached
        mismatched.inspectionSourceSHA256 = "different"
        XCTAssertTrue(mismatched.needsInspection)

        let outdatedResult = IPAInspectionResult(
            formatVersion: IPAInspectionResult.currentFormatVersion - 1,
            importedIPAID: identifier,
            sourceSHA256: hash,
            rootApplication: result.rootApplication,
            components: [],
            provisioningProfile: nil
        )
        var outdated = cached
        outdated.inspection = outdatedResult
        XCTAssertTrue(outdated.needsInspection)
    }
}
