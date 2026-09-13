import Foundation
import XCTest
@testable import DeviceKit

final class DeviceKitTests: XCTestCase {
    func testRefreshRequiresLaterInstalledExpiry() {
        let old = Date(timeIntervalSince1970: 100)
        XCTAssertTrue(RefreshVerification(oldExpiry: old, installedExpiry: old.addingTimeInterval(1)).succeeded)
        XCTAssertFalse(RefreshVerification(oldExpiry: old, installedExpiry: old).succeeded)
    }
}
