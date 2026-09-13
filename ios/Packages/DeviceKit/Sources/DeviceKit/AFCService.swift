import Foundation

public protocol AFCService: Sendable {
    func stageIPA(at localURL: URL) async throws -> String
}
