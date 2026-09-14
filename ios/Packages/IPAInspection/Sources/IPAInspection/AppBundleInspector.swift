import Foundation
import IPADomain

struct InspectedAppBundle {
    let metadata: AppBundleMetadata
    let plist: ParsedInfoPlist
}

struct AppBundleInspector {
    let infoPlistReader: any InfoPlistReading
    let policy: ArchiveSafetyPolicy

    init(
        infoPlistReader: (any InfoPlistReading)? = nil,
        policy: ArchiveSafetyPolicy = .default
    ) {
        self.infoPlistReader = infoPlistReader ?? InfoPlistReader(policy: policy)
        self.policy = policy
    }

    func inspect(appAt appURL: URL, relativePath: String) throws -> InspectedAppBundle {
        let fallbackName = appURL.deletingPathExtension().lastPathComponent
        let plist = try infoPlistReader.readInfoPlist(
            in: appURL,
            fallbackName: fallbackName,
            maximumBytes: policy.maximumInfoPlistBytes
        )
        return InspectedAppBundle(
            metadata: AppBundleMetadata(
                displayName: plist.displayName,
                bundleName: plist.bundleName,
                bundleIdentifier: plist.bundleIdentifier,
                shortVersion: plist.shortVersion,
                buildVersion: plist.buildVersion,
                executableName: plist.executableName,
                minimumOSVersion: plist.minimumOSVersion,
                deviceFamilies: plist.deviceFamilies,
                packageType: plist.packageType,
                platformName: plist.platformName,
                platformVersion: plist.platformVersion,
                sdkName: plist.sdkName,
                relativePath: relativePath
            ),
            plist: plist
        )
    }
}
