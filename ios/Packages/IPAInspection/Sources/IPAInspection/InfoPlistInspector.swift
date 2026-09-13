import Foundation

public protocol InfoPlistInspecting: Sendable {
    func readDictionary(at url: URL, maximumBytes: Int) throws -> [String: String]
}
