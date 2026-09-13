import Foundation
import IPADomain

public struct BundleGraphBuilder: Sendable {
    public init() {}

    /// Produces child-before-parent order and rejects cycles or missing nodes.
    public func signingOrder(components: [BundleComponent], rootID: UUID) throws -> [UUID] {
        var byID: [UUID: BundleComponent] = [:]
        for component in components {
            guard byID.updateValue(component, forKey: component.id) == nil else {
                throw IPAError.malformedMetadata("bundle graph contains a duplicate component")
            }
        }
        var visited = Set<UUID>()
        var active = Set<UUID>()
        var result: [UUID] = []
        func visit(_ id: UUID) throws {
            guard let component = byID[id] else { throw IPAError.malformedMetadata("bundle graph references a missing component") }
            guard !active.contains(id) else { throw IPAError.malformedMetadata("bundle graph contains a cycle") }
            guard !visited.contains(id) else { return }
            active.insert(id)
            for child in component.childIDs { try visit(child) }
            active.remove(id)
            visited.insert(id)
            result.append(id)
        }
        try visit(rootID)
        return result
    }
}
