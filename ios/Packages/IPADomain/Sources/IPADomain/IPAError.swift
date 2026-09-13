public enum IPAError: Error, Codable, Equatable, Sendable {
    case invalidArchive(String)
    case unsafeArchive(String)
    case malformedMetadata(String)
    case incompatibleSigning(String)
    case nativeFailure(code: Int32, message: String)
    case unsupported(String)
}
