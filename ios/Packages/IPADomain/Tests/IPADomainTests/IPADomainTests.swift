import XCTest
@testable import IPADomain

final class IPADomainTests: XCTestCase {
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
