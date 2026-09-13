import IPADomain

public protocol LibraryRepository: Sendable {
    func importedIPAs() async throws -> [ImportedIPA]
    func save(_ importedIPA: ImportedIPA) async throws
}
