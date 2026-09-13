public struct MachOInfo: Codable, Hashable, Sendable {
    public let architectures: [String]
    public let fileType: String
    public let minimumOSVersion: String?
    public let linkedDylibs: [String]

    public init(architectures: [String], fileType: String, minimumOSVersion: String?, linkedDylibs: [String]) {
        self.architectures = architectures
        self.fileType = fileType
        self.minimumOSVersion = minimumOSVersion
        self.linkedDylibs = linkedDylibs
    }
}
