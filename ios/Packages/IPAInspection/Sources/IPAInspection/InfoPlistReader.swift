import CoreFoundation
import Foundation
import IPADomain

public struct ParsedInfoPlist: Hashable, Sendable {
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
    public let iconNames: [String]
}

public protocol InfoPlistReading: Sendable {
    func readInfoPlist(in bundleURL: URL, fallbackName: String, maximumBytes: UInt64) throws -> ParsedInfoPlist
}

public struct InfoPlistReader: InfoPlistReading {
    private let policy: ArchiveSafetyPolicy

    public init(policy: ArchiveSafetyPolicy = .default) {
        self.policy = policy
    }

    public func readInfoPlist(
        in bundleURL: URL,
        fallbackName: String,
        maximumBytes: UInt64
    ) throws -> ParsedInfoPlist {
        let plistURL = bundleURL.appending(path: "Info.plist")
        guard FileManager().fileExists(atPath: plistURL.path) else {
            throw IPAError.missingInfoPlist
        }

        let values: URLResourceValues
        do {
            values = try plistURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey])
        } catch {
            throw IPAError.malformedInfoPlist
        }
        guard values.isRegularFile == true,
              values.isSymbolicLink != true,
              let byteCount = values.fileSize,
              byteCount >= 0,
              UInt64(byteCount) <= maximumBytes
        else {
            throw IPAError.malformedInfoPlist
        }

        let data: Data
        do {
            data = try Data(contentsOf: plistURL, options: [.mappedIfSafe])
        } catch {
            throw IPAError.malformedInfoPlist
        }
        return try parse(data: data, fallbackName: fallbackName)
    }

    public func parse(data: Data, fallbackName: String) throws -> ParsedInfoPlist {
        let propertyList: Any
        do {
            propertyList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            throw IPAError.malformedInfoPlist
        }
        guard let dictionary = propertyList as? [String: Any] else {
            throw IPAError.malformedInfoPlist
        }

        let displayName = string(dictionary["CFBundleDisplayName"])
            ?? string(dictionary["CFBundleName"])
            ?? fallbackName

        return ParsedInfoPlist(
            displayName: displayName,
            bundleName: string(dictionary["CFBundleName"]),
            bundleIdentifier: string(dictionary["CFBundleIdentifier"]),
            shortVersion: string(dictionary["CFBundleShortVersionString"]),
            buildVersion: string(dictionary["CFBundleVersion"]),
            executableName: string(dictionary["CFBundleExecutable"]),
            minimumOSVersion: string(dictionary["MinimumOSVersion"]),
            deviceFamilies: integerArray(dictionary["UIDeviceFamily"]),
            packageType: string(dictionary["CFBundlePackageType"]),
            platformName: string(dictionary["DTPlatformName"]),
            platformVersion: string(dictionary["DTPlatformVersion"]),
            sdkName: string(dictionary["DTSDKName"]),
            iconNames: iconNames(from: dictionary)
        )
    }

    private func string(_ value: Any?) -> String? {
        guard let value = value as? String else { return nil }
        return safeString(value)
    }

    private func safeString(_ value: String) -> String? {
        guard !value.isEmpty,
              value.utf8.count <= policy.maximumMetadataStringBytes,
              !value.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
        else { return nil }
        return value
    }

    private func integerArray(_ value: Any?) -> [Int] {
        if let values = value as? [NSNumber], values.count <= policy.maximumDeviceFamilyCount {
            return values.compactMap {
                CFGetTypeID($0) == CFBooleanGetTypeID() ? nil : $0.intValue
            }
        }
        if let value = value as? NSNumber,
           CFGetTypeID(value) != CFBooleanGetTypeID(),
           policy.maximumDeviceFamilyCount > 0 {
            return [value.intValue]
        }
        return []
    }

    private func iconNames(from dictionary: [String: Any]) -> [String] {
        var names: [String] = []
        var traversedValueCount = 0
        appendStrings(dictionary["CFBundleIconFiles"], to: &names)
        appendStrings(dictionary["CFBundleIconName"], to: &names)
        collectIconDeclarations(
            dictionary["CFBundleIcons"],
            into: &names,
            depth: 0,
            traversedValueCount: &traversedValueCount
        )
        collectIconDeclarations(
            dictionary["CFBundleIcons~ipad"],
            into: &names,
            depth: 0,
            traversedValueCount: &traversedValueCount
        )

        var seen = Set<String>()
        return names.compactMap { rawName in
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(name).inserted else { return nil }
            return name
        }.prefix(policy.maximumIconDeclarationCount).map { $0 }
    }

    private func collectIconDeclarations(
        _ value: Any?,
        into names: inout [String],
        depth: Int,
        traversedValueCount: inout Int
    ) {
        guard depth <= 8,
              names.count < policy.maximumIconDeclarationCount,
              traversedValueCount < policy.maximumInfoPlistTraversalValueCount
        else { return }
        traversedValueCount += 1
        if let dictionary = value as? [String: Any] {
            for (key, child) in dictionary {
                if key == "CFBundleIconFiles" || key == "CFBundleIconName" {
                    appendStrings(child, to: &names)
                } else {
                    collectIconDeclarations(
                        child,
                        into: &names,
                        depth: depth + 1,
                        traversedValueCount: &traversedValueCount
                    )
                }
            }
        } else if let array = value as? [Any] {
            for child in array {
                collectIconDeclarations(
                    child,
                    into: &names,
                    depth: depth + 1,
                    traversedValueCount: &traversedValueCount
                )
            }
        }
    }

    private func appendStrings(_ value: Any?, to names: inout [String]) {
        if let name = value as? String {
            if let name = safeString(name), names.count < policy.maximumIconDeclarationCount {
                names.append(name)
            }
        } else if let values = value as? [Any] {
            for value in values {
                guard names.count < policy.maximumIconDeclarationCount else { return }
                if let value = value as? String, let name = safeString(value) {
                    names.append(name)
                }
            }
        }
    }
}
