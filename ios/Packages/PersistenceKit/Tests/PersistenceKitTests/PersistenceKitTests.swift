import XCTest
@testable import PersistenceKit

@MainActor
final class PersistenceKitTests: XCTestCase {
    func testInMemoryContainerCanBeCreated() throws {
        _ = try PersistenceController(inMemory: true)
    }
}
