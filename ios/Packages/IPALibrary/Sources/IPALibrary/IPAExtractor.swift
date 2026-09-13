import Foundation
import IPADomain

public protocol IPAExtracting: Sendable {
    func extractValidatedArchive(at source: URL, to destination: URL) async throws
}

/// Integration boundary for a ZIPFoundation extractor. The implementation is intentionally
/// deferred until adversarial fixtures and resource-limit enforcement are in place.
public struct UnavailableIPAExtractor: IPAExtracting {
    public init() {}
    public func extractValidatedArchive(at source: URL, to destination: URL) async throws {
        throw IPAError.unsupported("secure IPA extraction is not implemented")
    }
}
