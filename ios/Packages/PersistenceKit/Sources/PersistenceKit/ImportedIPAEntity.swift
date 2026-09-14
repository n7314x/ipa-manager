import Foundation
import IPADomain
import SwiftData

@Model
public final class ImportedIPAEntity {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var sourceSHA256: String
    public var originalFilename: String = ""
    public var originalRelativePath: String
    public var byteSize: Int64 = 0
    public var importedAt: Date

    public var inspectionStatusRaw: String = "notInspected"
    public var inspectionFailureRaw: String?
    public var inspectionSourceSHA256: String?
    public var inspectionFormatVersion: Int?
    public var inspectedAt: Date?

    public var rootDisplayName: String?
    public var rootBundleName: String?
    public var rootBundleIdentifier: String?
    public var rootShortVersion: String?
    public var rootBuildVersion: String?
    public var rootExecutableName: String?
    public var rootMinimumOSVersion: String?
    public var rootDeviceFamiliesData: Data?
    public var rootPackageType: String?
    public var rootPlatformName: String?
    public var rootPlatformVersion: String?
    public var rootSDKName: String?
    public var rootRelativePath: String?

    public var iconRelativePath: String?
    public var iconPixelWidth: Int?
    public var iconPixelHeight: Int?
    public var iconByteSize: Int64?

    public var provisioningPresent: Bool = false
    public var provisioningDecodeStatusRaw: String?
    public var provisioningRelativePath: String?
    public var provisioningUUID: String?
    public var provisioningName: String?
    public var provisioningTeamIdentifiersData: Data?
    public var provisioningTeamName: String?
    public var provisioningPrefixesData: Data?
    public var provisioningExpirationDate: Date?
    public var provisioningCreationDate: Date?
    public var provisioningDeviceCount: Int?
    public var provisioningAllDevices: Bool?
    public var provisioningEntitlementsData: Data?

    @Relationship(deleteRule: .cascade, inverse: \InspectionBundleComponentEntity.importedIPA)
    public var inspectionComponents: [InspectionBundleComponentEntity] = []

    public init(
        id: UUID,
        originalFilename: String,
        sourceSHA256: String,
        originalRelativePath: String,
        byteSize: Int64,
        importedAt: Date
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.sourceSHA256 = sourceSHA256
        self.originalRelativePath = originalRelativePath
        self.byteSize = byteSize
        self.importedAt = importedAt
    }

    public convenience init(importedIPA: ImportedIPA) {
        self.init(
            id: importedIPA.id,
            originalFilename: importedIPA.originalFilename,
            sourceSHA256: importedIPA.sourceSHA256,
            originalRelativePath: importedIPA.originalRelativePath,
            byteSize: importedIPA.byteSize,
            importedAt: importedIPA.importedAt
        )
        applyInspection(
            status: importedIPA.inspectionStatus,
            sourceSHA256: importedIPA.inspectionSourceSHA256,
            result: importedIPA.inspection
        )
    }

    public var domainModel: ImportedIPA {
        let sourceMatches = inspectionSourceSHA256 == sourceSHA256
        let decodedInspection = sourceMatches ? inspectionDomainModel : nil
        let cacheIsCurrent = decodedInspection?.formatVersion == IPAInspectionResult.currentFormatVersion
        let cachedInspection = cacheIsCurrent ? decodedInspection : nil
        let status: InspectionStatus
        if !sourceMatches, inspectionSourceSHA256 != nil {
            status = .notInspected
        } else {
            switch inspectionStatusRaw {
            case "inspecting":
                status = .inspecting
            case "inspected":
                status = cacheIsCurrent ? .inspected : .failed(.invalidCache)
            case "failed":
                status = .failed(InspectionFailureReason(rawValue: inspectionFailureRaw ?? "") ?? .unknown)
            default:
                status = .notInspected
            }
        }

        return ImportedIPA(
            id: id,
            originalFilename: originalFilename,
            sourceSHA256: sourceSHA256,
            originalRelativePath: originalRelativePath,
            byteSize: byteSize,
            importedAt: importedAt,
            inspectionStatus: status,
            inspectionSourceSHA256: sourceMatches ? inspectionSourceSHA256 : nil,
            inspection: cachedInspection
        )
    }

    public func applyInspection(
        status: InspectionStatus,
        sourceSHA256: String?,
        result: IPAInspectionResult?
    ) {
        inspectionSourceSHA256 = sourceSHA256
        switch status {
        case .notInspected:
            inspectionStatusRaw = "notInspected"
            inspectionFailureRaw = nil
        case .inspecting:
            inspectionStatusRaw = "inspecting"
            inspectionFailureRaw = nil
        case .inspected:
            inspectionStatusRaw = "inspected"
            inspectionFailureRaw = nil
        case .failed(let reason):
            inspectionStatusRaw = "failed"
            inspectionFailureRaw = reason.rawValue
        }

        clearDerivedInspection()
        guard let result else { return }
        inspectionFormatVersion = result.formatVersion
        inspectedAt = result.inspectedAt
        let app = result.rootApplication
        rootDisplayName = app.displayName
        rootBundleName = app.bundleName
        rootBundleIdentifier = app.bundleIdentifier
        rootShortVersion = app.shortVersion
        rootBuildVersion = app.buildVersion
        rootExecutableName = app.executableName
        rootMinimumOSVersion = app.minimumOSVersion
        rootDeviceFamiliesData = Self.encode(app.deviceFamilies)
        rootPackageType = app.packageType
        rootPlatformName = app.platformName
        rootPlatformVersion = app.platformVersion
        rootSDKName = app.sdkName
        rootRelativePath = app.relativePath
        iconRelativePath = app.icon?.relativePath
        iconPixelWidth = app.icon?.pixelWidth
        iconPixelHeight = app.icon?.pixelHeight
        iconByteSize = app.icon?.byteSize

        inspectionComponents = result.components.map(InspectionBundleComponentEntity.init(component:))
        for component in inspectionComponents { component.importedIPA = self }

        if let profile = result.provisioningProfile {
            provisioningPresent = true
            provisioningDecodeStatusRaw = profile.decodeStatus.rawValue
            provisioningRelativePath = profile.relativePath
            provisioningUUID = profile.profileUUID
            provisioningName = profile.name
            provisioningTeamIdentifiersData = Self.encode(profile.teamIdentifiers)
            provisioningTeamName = profile.teamName
            provisioningPrefixesData = Self.encode(profile.applicationIdentifierPrefixes)
            provisioningExpirationDate = profile.expirationDate
            provisioningCreationDate = profile.creationDate
            provisioningDeviceCount = profile.provisionedDevicesCount
            provisioningAllDevices = profile.provisionsAllDevices
            provisioningEntitlementsData = profile.entitlements.flatMap { Self.encode($0) }
        }
    }

    private var inspectionDomainModel: IPAInspectionResult? {
        guard let inspectionFormatVersion,
              let inspectedAt,
              let inspectionSourceSHA256,
              let rootDisplayName,
              let rootRelativePath
        else { return nil }

        let icon: AppIconMetadata?
        if let iconRelativePath, let iconByteSize {
            icon = AppIconMetadata(
                relativePath: iconRelativePath,
                pixelWidth: iconPixelWidth,
                pixelHeight: iconPixelHeight,
                byteSize: iconByteSize
            )
        } else {
            icon = nil
        }
        let app = AppBundleMetadata(
            displayName: rootDisplayName,
            bundleName: rootBundleName,
            bundleIdentifier: rootBundleIdentifier,
            shortVersion: rootShortVersion,
            buildVersion: rootBuildVersion,
            executableName: rootExecutableName,
            minimumOSVersion: rootMinimumOSVersion,
            deviceFamilies: Self.decode([Int].self, from: rootDeviceFamiliesData) ?? [],
            packageType: rootPackageType,
            platformName: rootPlatformName,
            platformVersion: rootPlatformVersion,
            sdkName: rootSDKName,
            relativePath: rootRelativePath,
            icon: icon
        )

        let profile: ProvisioningProfileMetadata?
        if provisioningPresent, let relativePath = provisioningRelativePath {
            profile = ProvisioningProfileMetadata(
                relativePath: relativePath,
                decodeStatus: ProvisioningProfileDecodeStatus(
                    rawValue: provisioningDecodeStatusRaw ?? ""
                ) ?? .unavailable,
                profileUUID: provisioningUUID,
                name: provisioningName,
                teamIdentifiers: Self.decode([String].self, from: provisioningTeamIdentifiersData) ?? [],
                teamName: provisioningTeamName,
                applicationIdentifierPrefixes: Self.decode([String].self, from: provisioningPrefixesData) ?? [],
                expirationDate: provisioningExpirationDate,
                creationDate: provisioningCreationDate,
                provisionedDevicesCount: provisioningDeviceCount,
                provisionsAllDevices: provisioningAllDevices,
                entitlements: Self.decode(
                    [String: PropertyListValue].self,
                    from: provisioningEntitlementsData
                )
            )
        } else {
            profile = nil
        }

        return IPAInspectionResult(
            formatVersion: inspectionFormatVersion,
            importedIPAID: id,
            sourceSHA256: inspectionSourceSHA256,
            rootApplication: app,
            components: inspectionComponents.map(\.domainModel).sorted {
                if $0.kind.rawValue == $1.kind.rawValue {
                    return $0.relativePath < $1.relativePath
                }
                return $0.kind.rawValue < $1.kind.rawValue
            },
            provisioningProfile: profile,
            existingEntitlements: .unavailable,
            inspectedAt: inspectedAt
        )
    }

    private func clearDerivedInspection() {
        inspectionFormatVersion = nil
        inspectedAt = nil
        rootDisplayName = nil
        rootBundleName = nil
        rootBundleIdentifier = nil
        rootShortVersion = nil
        rootBuildVersion = nil
        rootExecutableName = nil
        rootMinimumOSVersion = nil
        rootDeviceFamiliesData = nil
        rootPackageType = nil
        rootPlatformName = nil
        rootPlatformVersion = nil
        rootSDKName = nil
        rootRelativePath = nil
        iconRelativePath = nil
        iconPixelWidth = nil
        iconPixelHeight = nil
        iconByteSize = nil
        inspectionComponents = []
        provisioningPresent = false
        provisioningDecodeStatusRaw = nil
        provisioningRelativePath = nil
        provisioningUUID = nil
        provisioningName = nil
        provisioningTeamIdentifiersData = nil
        provisioningTeamName = nil
        provisioningPrefixesData = nil
        provisioningExpirationDate = nil
        provisioningCreationDate = nil
        provisioningDeviceCount = nil
        provisioningAllDevices = nil
        provisioningEntitlementsData = nil
    }

    private static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
