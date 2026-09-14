import Foundation
import IPADomain
import SwiftData

@Model
public final class InspectionBundleComponentEntity {
    @Attribute(.unique) public var id: UUID
    public var kindRaw: String
    public var relativePath: String
    public var bundleIdentifier: String?
    public var displayName: String?
    public var version: String?
    public var buildVersion: String?
    public var executableRelativePath: String?
    public var childIDsData: Data?
    public var importedIPA: ImportedIPAEntity?

    public init(
        id: UUID,
        kindRaw: String,
        relativePath: String,
        bundleIdentifier: String? = nil,
        displayName: String? = nil,
        version: String? = nil,
        buildVersion: String? = nil,
        executableRelativePath: String? = nil,
        childIDsData: Data? = nil
    ) {
        self.id = id
        self.kindRaw = kindRaw
        self.relativePath = relativePath
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.version = version
        self.buildVersion = buildVersion
        self.executableRelativePath = executableRelativePath
        self.childIDsData = childIDsData
    }

    public convenience init(component: BundleComponent) {
        self.init(
            id: component.id,
            kindRaw: component.kind.rawValue,
            relativePath: component.relativePath,
            bundleIdentifier: component.bundleIdentifier,
            displayName: component.displayName,
            version: component.version,
            buildVersion: component.buildVersion,
            executableRelativePath: component.executableRelativePath,
            childIDsData: try? JSONEncoder().encode(component.childIDs)
        )
    }

    public var domainModel: BundleComponent {
        BundleComponent(
            id: id,
            kind: BundleComponent.Kind(rawValue: kindRaw) ?? .framework,
            relativePath: relativePath,
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            version: version,
            buildVersion: buildVersion,
            executableRelativePath: executableRelativePath,
            childIDs: childIDsData.flatMap { try? JSONDecoder().decode([UUID].self, from: $0) } ?? []
        )
    }
}
