import Foundation

public enum InspectionFailureReason: String, Codable, Hashable, Sendable {
    case unsafeArchive
    case resourceLimit
    case invalidStructure
    case malformedMetadata
    case unreadableArchive
    case invalidCache
    case unknown
}

public enum InspectionStatus: Codable, Hashable, Sendable {
    case notInspected
    case inspecting
    case inspected
    case failed(InspectionFailureReason)
}

public enum PropertyListValue: Codable, Hashable, Sendable {
    case string(String)
    case integer(Int64)
    case real(Double)
    case boolean(Bool)
    case date(Date)
    case data(Data)
    case array([PropertyListValue])
    case dictionary([String: PropertyListValue])
}

public enum ExistingEntitlementsInspection: Codable, Hashable, Sendable {
    case notInspected
    case unavailable
    case present([String: PropertyListValue])
}

public struct AppIconMetadata: Codable, Hashable, Sendable {
    public let relativePath: String
    public let pixelWidth: Int?
    public let pixelHeight: Int?
    public let byteSize: Int64

    public init(relativePath: String, pixelWidth: Int?, pixelHeight: Int?, byteSize: Int64) {
        self.relativePath = relativePath
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.byteSize = byteSize
    }
}

public struct AppBundleMetadata: Codable, Hashable, Sendable {
    public let displayName: String
    public let bundleName: String?
    public let bundleIdentifier: String?
    public let shortVersion: String?
    public let buildVersion: String?
    public let executableName: String?
    public let minimumOSVersion: String?
    public let deviceFamilies: [Int]
    public let packageType: String?
    public let platformName: String?
    public let platformVersion: String?
    public let sdkName: String?
    public let relativePath: String
    public let icon: AppIconMetadata?

    public init(
        displayName: String,
        bundleName: String? = nil,
        bundleIdentifier: String? = nil,
        shortVersion: String? = nil,
        buildVersion: String? = nil,
        executableName: String? = nil,
        minimumOSVersion: String? = nil,
        deviceFamilies: [Int] = [],
        packageType: String? = nil,
        platformName: String? = nil,
        platformVersion: String? = nil,
        sdkName: String? = nil,
        relativePath: String,
        icon: AppIconMetadata? = nil
    ) {
        self.displayName = displayName
        self.bundleName = bundleName
        self.bundleIdentifier = bundleIdentifier
        self.shortVersion = shortVersion
        self.buildVersion = buildVersion
        self.executableName = executableName
        self.minimumOSVersion = minimumOSVersion
        self.deviceFamilies = deviceFamilies
        self.packageType = packageType
        self.platformName = platformName
        self.platformVersion = platformVersion
        self.sdkName = sdkName
        self.relativePath = relativePath
        self.icon = icon
    }

    public func withIcon(_ icon: AppIconMetadata?) -> AppBundleMetadata {
        AppBundleMetadata(
            displayName: displayName,
            bundleName: bundleName,
            bundleIdentifier: bundleIdentifier,
            shortVersion: shortVersion,
            buildVersion: buildVersion,
            executableName: executableName,
            minimumOSVersion: minimumOSVersion,
            deviceFamilies: deviceFamilies,
            packageType: packageType,
            platformName: platformName,
            platformVersion: platformVersion,
            sdkName: sdkName,
            relativePath: relativePath,
            icon: icon
        )
    }
}

public enum ProvisioningProfileDecodeStatus: String, Codable, Hashable, Sendable {
    case decoded
    case unavailable
}

public struct ProvisioningProfileMetadata: Codable, Hashable, Sendable {
    public let relativePath: String
    public let decodeStatus: ProvisioningProfileDecodeStatus
    public let profileUUID: String?
    public let name: String?
    public let teamIdentifiers: [String]
    public let teamName: String?
    public let applicationIdentifierPrefixes: [String]
    public let expirationDate: Date?
    public let creationDate: Date?
    public let provisionedDevicesCount: Int?
    public let provisionsAllDevices: Bool?
    public let entitlements: [String: PropertyListValue]?

    public init(
        relativePath: String,
        decodeStatus: ProvisioningProfileDecodeStatus,
        profileUUID: String? = nil,
        name: String? = nil,
        teamIdentifiers: [String] = [],
        teamName: String? = nil,
        applicationIdentifierPrefixes: [String] = [],
        expirationDate: Date? = nil,
        creationDate: Date? = nil,
        provisionedDevicesCount: Int? = nil,
        provisionsAllDevices: Bool? = nil,
        entitlements: [String: PropertyListValue]? = nil
    ) {
        self.relativePath = relativePath
        self.decodeStatus = decodeStatus
        self.profileUUID = profileUUID
        self.name = name
        self.teamIdentifiers = teamIdentifiers
        self.teamName = teamName
        self.applicationIdentifierPrefixes = applicationIdentifierPrefixes
        self.expirationDate = expirationDate
        self.creationDate = creationDate
        self.provisionedDevicesCount = provisionedDevicesCount
        self.provisionsAllDevices = provisionsAllDevices
        self.entitlements = entitlements
    }
}

public struct IPAInspectionResult: Codable, Hashable, Sendable {
    public static let currentFormatVersion = 1

    public let formatVersion: Int
    public let importedIPAID: UUID
    public let sourceSHA256: String
    public let rootApplication: AppBundleMetadata
    public let components: [BundleComponent]
    public let provisioningProfile: ProvisioningProfileMetadata?
    public let existingEntitlements: ExistingEntitlementsInspection
    public let inspectedAt: Date

    public init(
        formatVersion: Int = IPAInspectionResult.currentFormatVersion,
        importedIPAID: UUID,
        sourceSHA256: String,
        rootApplication: AppBundleMetadata,
        components: [BundleComponent],
        provisioningProfile: ProvisioningProfileMetadata?,
        existingEntitlements: ExistingEntitlementsInspection = .unavailable,
        inspectedAt: Date = Date()
    ) {
        self.formatVersion = formatVersion
        self.importedIPAID = importedIPAID
        self.sourceSHA256 = sourceSHA256
        self.rootApplication = rootApplication
        self.components = components
        self.provisioningProfile = provisioningProfile
        self.existingEntitlements = existingEntitlements
        self.inspectedAt = inspectedAt
    }
}
