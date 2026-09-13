import IPADomain

public struct DeduplicationService: Sendable {
    public init() {}
    public func existingImport(for sha256: String, in imports: [ImportedIPA]) -> ImportedIPA? {
        imports.first { $0.sourceSHA256 == sha256 }
    }
}
