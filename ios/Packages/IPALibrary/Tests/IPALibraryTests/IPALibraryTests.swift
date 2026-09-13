import XCTest
@testable import IPALibrary

final class IPALibraryTests: XCTestCase {
    func testArchivePolicyRejectsTraversal() {
        XCTAssertThrowsError(try ArchiveSafetyPolicy.default.validate([
            ArchiveEntryDescriptor(path: "Payload/../secret", compressedSize: 1, uncompressedSize: 1),
        ]))
    }

    func testPayloadRequiresOneTopLevelApp() throws {
        let app = try IPAValidator().validatePayloadPaths(["Payload/Demo.app/Info.plist"])
        XCTAssertEqual(app, "Payload/Demo.app")
    }
}
