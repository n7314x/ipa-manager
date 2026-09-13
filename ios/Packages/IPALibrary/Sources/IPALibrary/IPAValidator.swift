import Foundation
import IPADomain

public struct IPAValidator: Sendable {
    public init() {}

    public func validatePayloadPaths(_ paths: [String]) throws -> String {
        let apps = Set(paths.compactMap { path -> String? in
            let parts = path.split(separator: "/")
            guard parts.count >= 2, parts[0] == "Payload", parts[1].hasSuffix(".app") else { return nil }
            return "Payload/\(parts[1])"
        })
        guard apps.count == 1, let app = apps.first else {
            throw IPAError.invalidArchive("expected exactly one top-level Payload app")
        }
        return app
    }
}
