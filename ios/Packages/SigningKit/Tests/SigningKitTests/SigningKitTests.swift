import XCTest
import IPADomain
@testable import SigningKit

final class SigningKitTests: XCTestCase {
    func testEntitlementPolicyIntersectsInputs() {
        let policy = EntitlementPolicy(allowedKeys: ["application-identifier"])
        let result = policy.effective(
            original: EntitlementSnapshot(values: ["application-identifier": "TEAM.app", "debug": "true"]),
            authorized: EntitlementSnapshot(values: ["application-identifier": "TEAM.app"])
        )
        XCTAssertEqual(result.values, ["application-identifier": "TEAM.app"])
    }
}
