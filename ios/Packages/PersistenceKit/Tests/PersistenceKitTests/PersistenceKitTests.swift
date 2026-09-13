import Foundation
import IPADomain
import XCTest
@testable import PersistenceKit

@MainActor
final class PersistenceKitTests: XCTestCase {
    func testInMemoryContainerCanBeCreated() throws {
        _ = try PersistenceController(inMemory: true)
    }

    func testImportedIPAEntityDomainRoundTrip() {
        let expected = makeImportedIPA()
        let entity = ImportedIPAEntity(importedIPA: expected)

        XCTAssertEqual(entity.domainModel, expected)
    }

    func testPersistenceRetrievalAndDuplicateHashLookup() async throws {
        let controller = try PersistenceController(inMemory: true)
        let store = controller.makeImportedIPAStore()
        let expected = makeImportedIPA()

        try await store.save(expected)

        let items = try await store.listImportedIPAs()
        XCTAssertEqual(items, [expected])
        let foundByID = try await store.importedIPA(id: expected.id)
        XCTAssertEqual(foundByID, expected)
        let foundByHash = try await store.findBySHA256(expected.sourceSHA256)
        XCTAssertEqual(foundByHash, expected)
    }

    func testDeletion() async throws {
        let controller = try PersistenceController(inMemory: true)
        let store = controller.makeImportedIPAStore()
        let expected = makeImportedIPA()
        try await store.save(expected)

        try await store.removeImportedIPA(id: expected.id)

        let deleted = try await store.importedIPA(id: expected.id)
        XCTAssertNil(deleted)
        let remaining = try await store.listImportedIPAs()
        XCTAssertTrue(remaining.isEmpty)
    }

    private func makeImportedIPA() -> ImportedIPA {
        ImportedIPA(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            originalFilename: "Synthetic.ipa",
            sourceSHA256: String(repeating: "a", count: 64),
            originalRelativePath: "Library/11111111-2222-3333-4444-555555555555/original.ipa",
            byteSize: 1_024,
            importedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
