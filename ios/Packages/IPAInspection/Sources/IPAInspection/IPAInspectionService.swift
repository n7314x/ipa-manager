import Foundation
import IPADomain

public struct IPAInspectionRequest: Hashable, Sendable {
    public let importedIPAID: UUID
    public let sourceSHA256: String
    public let originalIPAURL: URL
    public let workDirectory: URL
    public let metadataDirectory: URL
    public let iconCacheRelativePath: String

    public init(
        importedIPAID: UUID,
        sourceSHA256: String,
        originalIPAURL: URL,
        workDirectory: URL,
        metadataDirectory: URL,
        iconCacheRelativePath: String
    ) {
        self.importedIPAID = importedIPAID
        self.sourceSHA256 = sourceSHA256
        self.originalIPAURL = originalIPAURL
        self.workDirectory = workDirectory
        self.metadataDirectory = metadataDirectory
        self.iconCacheRelativePath = iconCacheRelativePath
    }
}

public protocol IPAInspecting: Sendable {
    func inspect(_ request: IPAInspectionRequest) async throws -> IPAInspectionResult
}

public actor IPAInspectionService: IPAInspecting {
    private let policy: ArchiveSafetyPolicy
    private let capacityProvider: any InspectionStorageCapacityProviding
    private let dateProvider: @Sendable () -> Date
    private let fileManager: FileManager

    public init(
        policy: ArchiveSafetyPolicy = .default,
        capacityProvider: any InspectionStorageCapacityProviding = FoundationInspectionStorageCapacityProvider(),
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.policy = policy
        self.capacityProvider = capacityProvider
        self.dateProvider = dateProvider
        self.fileManager = FileManager()
    }

    public func inspect(_ request: IPAInspectionRequest) async throws -> IPAInspectionResult {
        try Task.checkCancellation()
        let iconCacheURL = request.metadataDirectory.appending(path: "app-icon.png")
        try? fileManager.removeItem(at: iconCacheURL)
        var retainIconCache = false
        defer {
            if !retainIconCache { try? fileManager.removeItem(at: iconCacheURL) }
        }
        let workspace: IPAExtractionWorkspace
        do {
            workspace = try IPAExtractionWorkspace(parent: request.workDirectory, fileManager: fileManager)
        } catch {
            throw IPAError.inspectionFailure
        }
        defer { workspace.remove() }

        let preflight = try ArchivePreflightValidator(policy: policy).preflight(
            archiveAt: request.originalIPAURL
        )
        try Task.checkCancellation()
        try InspectionStorageCapacityGuard(
            policy: policy,
            capacityProvider: capacityProvider
        ).validate(
            declaredUncompressedBytes: preflight.totalUncompressedBytes,
            workspaceURL: workspace.extractionRoot
        )
        try Task.checkCancellation()
        try SafeArchiveExtractor(policy: policy).extract(
            archiveAt: request.originalIPAURL,
            preflight: preflight,
            to: workspace.extractionRoot,
            fileManager: fileManager
        )
        try Task.checkCancellation()

        let rootApplicationURL = try policy.destinationURL(
            for: preflight.rootApplicationRelativePath,
            inside: workspace.extractionRoot
        )
        let rootValues = try rootApplicationURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard rootValues.isDirectory == true, rootValues.isSymbolicLink != true else {
            throw IPAError.invalidPayloadStructure
        }

        let inspectedApp = try AppBundleInspector(policy: policy).inspect(
            appAt: rootApplicationURL,
            relativePath: preflight.rootApplicationRelativePath
        )
        let components = try BundleComponentScanner(policy: policy).scan(
            rootApplicationURL: rootApplicationURL,
            rootRelativePath: preflight.rootApplicationRelativePath,
            rootMetadata: inspectedApp.metadata
        )

        let profileRelativePath = "\(preflight.rootApplicationRelativePath)/embedded.mobileprovision"
        let profileURL = rootApplicationURL.appending(path: "embedded.mobileprovision")
        let provisioningProfile: ProvisioningProfileMetadata?
        if fileManager.fileExists(atPath: profileURL.path) {
            provisioningProfile = (try? ProvisioningProfileReader().readProfile(
                at: profileURL,
                relativePath: profileRelativePath,
                policy: policy
            )) ?? ProvisioningProfileMetadata(
                relativePath: profileRelativePath,
                decodeStatus: .unavailable
            )
        } else {
            provisioningProfile = nil
        }
        try Task.checkCancellation()

        let icon = try? AppIconResolver(policy: policy).resolveAndCache(
            appAt: rootApplicationURL,
            declaredNames: inspectedApp.plist.iconNames,
            cacheURL: iconCacheURL,
            cacheRelativePath: request.iconCacheRelativePath,
            fileManager: fileManager
        )
        if icon == nil { try? fileManager.removeItem(at: iconCacheURL) }

        try Task.checkCancellation()
        let result = IPAInspectionResult(
            importedIPAID: request.importedIPAID,
            sourceSHA256: request.sourceSHA256,
            rootApplication: inspectedApp.metadata.withIcon(icon),
            components: components,
            provisioningProfile: provisioningProfile,
            existingEntitlements: .unavailable,
            inspectedAt: dateProvider()
        )
        retainIconCache = true
        return result
    }
}

public struct UnavailableIPAInspector: IPAInspecting {
    public init() {}

    public func inspect(_ request: IPAInspectionRequest) async throws -> IPAInspectionResult {
        throw IPAError.unsupported("full bundle inspection is unavailable")
    }
}

public extension InspectionFailureReason {
    init(inspectionError error: Error) {
        guard let error = error as? IPAError else {
            self = .unknown
            return
        }
        switch error {
        case .unsafeArchive, .duplicateArchiveEntry, .suspiciousCompressionRatio:
            self = .unsafeArchive
        case .archiveTooLarge, .archiveEntryTooLarge, .tooManyArchiveEntries,
             .sourceTooLarge, .insufficientStorage:
            self = .resourceLimit
        case .invalidArchive, .invalidPayloadStructure, .missingApplicationBundle,
             .multipleRootApplications, .missingInfoPlist:
            self = .invalidStructure
        case .malformedInfoPlist, .malformedMetadata:
            self = .malformedMetadata
        case .unsupportedArchive, .inaccessibleSource:
            self = .unreadableArchive
        default:
            self = .unknown
        }
    }
}
