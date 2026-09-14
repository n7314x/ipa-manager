import Foundation
import IPADomain
import IPALibrary
import PersistenceKit

@MainActor
final class AppContainer {
    let persistenceController: PersistenceController
    let libraryService: IPALibraryService

    init() throws {
        let fileManager = FileManager()
        let persistenceController = try PersistenceController()
        let applicationSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let store = persistenceController.makeImportedIPAStore()
        let repository = LibraryPersistenceRepository(store: store)

        self.persistenceController = persistenceController
        self.libraryService = IPALibraryService(
            layout: LibraryFileLayout(applicationSupportURL: applicationSupportURL),
            repository: repository
        )
    }
}

private struct LibraryPersistenceRepository: LibraryRepository {
    let store: ImportedIPAStore

    func listImportedIPAs() async throws -> [ImportedIPA] {
        try await store.listImportedIPAs()
    }

    func importedIPA(id: UUID) async throws -> ImportedIPA? {
        try await store.importedIPA(id: id)
    }

    func findBySHA256(_ sha256: String) async throws -> ImportedIPA? {
        try await store.findBySHA256(sha256)
    }

    func save(_ importedIPA: ImportedIPA) async throws {
        try await store.save(importedIPA)
    }

    func removeImportedIPA(id: UUID) async throws {
        try await store.removeImportedIPA(id: id)
    }
}
