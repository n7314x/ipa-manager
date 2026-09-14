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
}
