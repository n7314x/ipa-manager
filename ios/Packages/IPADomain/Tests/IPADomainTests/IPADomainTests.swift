import XCTest
@testable import IPADomain

final class IPADomainTests: XCTestCase {
    func testImportedIPAKeepsSourceHash() {
        let imported = ImportedIPA(sourceSHA256: "abc123", originalRelativePath: "Library/id/original.ipa")
        XCTAssertEqual(imported.sourceSHA256, "abc123")
    }
}
