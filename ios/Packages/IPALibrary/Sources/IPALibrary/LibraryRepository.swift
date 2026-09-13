import Foundation
import IPADomain

public protocol LibraryRepository: Sendable {
    func listImportedIPAs() async throws -> [ImportedIPA]
    func importedIPA(id: UUID) async throws -> ImportedIPA?
    func findBySHA256(_ sha256: String) async throws -> ImportedIPA?
    func save(_ importedIPA: ImportedIPA) async throws
    func removeImportedIPA(id: UUID) async throws
}
