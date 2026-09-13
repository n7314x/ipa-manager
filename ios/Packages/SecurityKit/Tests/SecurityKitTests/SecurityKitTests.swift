import Foundation
import XCTest
@testable import SecurityKit

final class SecurityKitTests: XCTestCase {
    func testSecretBufferCanBeCleared() {
        let secret = SecretBuffer(Data("secret".utf8))
        secret.clear()
        let count = secret.withUnsafeBytes { $0.count }
        XCTAssertEqual(count, 0)
    }
}
