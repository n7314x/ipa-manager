import Foundation
import XCTest
import IPADomain
@testable import IPAInspection

final class IPAInspectionTests: XCTestCase {
    func testBundleGraphSignsParentLast() throws {
        let child = BundleComponent(kind: .extensionBundle, relativePath: "Payload/App.app/PlugIns/Widget.appex")
        let root = BundleComponent(kind: .application, relativePath: "Payload/App.app", childIDs: [child.id])
        XCTAssertEqual(try BundleGraphBuilder().signingOrder(components: [root, child], rootID: root.id), [child.id, root.id])
    }
}
