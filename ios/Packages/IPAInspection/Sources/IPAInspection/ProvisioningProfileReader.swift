import CoreFoundation
import Foundation
import IPADomain
#if os(macOS)
import Security
#endif

public protocol ProvisioningProfileReading: Sendable {
    func readProfile(at url: URL, relativePath: String, policy: ArchiveSafetyPolicy) throws -> ProvisioningProfileMetadata
}

public struct ProvisioningProfileReader: ProvisioningProfileReading {
    public init() {}

    public func readProfile(
        at url: URL,
        relativePath: String,
        policy: ArchiveSafetyPolicy = .default
    ) throws -> ProvisioningProfileMetadata {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey])
        guard values.isRegularFile == true,
              values.isSymbolicLink != true,
              let size = values.fileSize,
              size > 0,
              UInt64(size) <= policy.maximumProvisioningProfileBytes
        else {
            throw IPAError.inspectionFailure
        }
        let profileData = try Data(contentsOf: url, options: [.mappedIfSafe])
#if os(macOS)
        let decodedData = try decodeCMSContent(profileData)
        return try parseDecodedPropertyList(
            decodedData,
            relativePath: relativePath,
            maximumValueCount: policy.maximumProvisioningValueCount
        )
#else
        // CMSDecoder is public on macOS but SPI-only on iOS. Presence is still useful
        // metadata; callers represent decoding as unavailable without using private API.
        _ = profileData
        return ProvisioningProfileMetadata(
            relativePath: relativePath,
            decodeStatus: .unavailable
        )
#endif
    }

    func parseDecodedPropertyList(
        _ data: Data,
        relativePath: String,
        maximumValueCount: Int
    ) throws -> ProvisioningProfileMetadata {
        let propertyList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let dictionary = propertyList as? [String: Any] else {
            throw IPAError.inspectionFailure
        }

        var valueCount = 0
        let rawEntitlements = dictionary["Entitlements"] as? [String: Any]
        let entitlements = try rawEntitlements?.reduce(into: [String: PropertyListValue]()) { result, element in
            result[element.key] = try propertyListValue(
                element.value,
                depth: 0,
                count: &valueCount,
                maximumValueCount: maximumValueCount
            )
        }

        return ProvisioningProfileMetadata(
            relativePath: relativePath,
            decodeStatus: .decoded,
            profileUUID: dictionary["UUID"] as? String,
            name: dictionary["Name"] as? String,
            teamIdentifiers: stringArray(dictionary["TeamIdentifier"]),
            teamName: dictionary["TeamName"] as? String,
            applicationIdentifierPrefixes: stringArray(dictionary["ApplicationIdentifierPrefix"]),
            expirationDate: dictionary["ExpirationDate"] as? Date,
            creationDate: dictionary["CreationDate"] as? Date,
            provisionedDevicesCount: (dictionary["ProvisionedDevices"] as? [Any])?.count,
            provisionsAllDevices: dictionary["ProvisionsAllDevices"] as? Bool,
            entitlements: entitlements
        )
    }

#if os(macOS)
    private func decodeCMSContent(_ data: Data) throws -> Data {
        var decoder: CMSDecoder?
        guard CMSDecoderCreate(&decoder) == errSecSuccess, let decoder else {
            throw IPAError.inspectionFailure
        }
        let updateStatus = data.withUnsafeBytes { bytes -> OSStatus in
            guard let baseAddress = bytes.baseAddress else { return errSecParam }
            return CMSDecoderUpdateMessage(decoder, baseAddress, data.count)
        }
        guard updateStatus == errSecSuccess,
              CMSDecoderFinalizeMessage(decoder) == errSecSuccess
        else {
            throw IPAError.inspectionFailure
        }
        var content: CFData?
        guard CMSDecoderCopyContent(decoder, &content) == errSecSuccess,
              let content
        else {
            throw IPAError.inspectionFailure
        }
        return content as Data
    }
#endif

    private func stringArray(_ value: Any?) -> [String] {
        if let values = value as? [String] { return values }
        if let value = value as? String { return [value] }
        return []
    }

    private func propertyListValue(
        _ value: Any,
        depth: Int,
        count: inout Int,
        maximumValueCount: Int
    ) throws -> PropertyListValue {
        guard depth <= 16, count < maximumValueCount else {
            throw IPAError.inspectionFailure
        }
        count += 1

        switch value {
        case let value as String:
            return .string(value)
        case let value as Date:
            return .date(value)
        case let value as Data:
            return .data(value)
        case let value as NSNumber:
            if CFGetTypeID(value) == CFBooleanGetTypeID() { return .boolean(value.boolValue) }
            let type = String(cString: value.objCType)
            if type == "f" || type == "d" { return .real(value.doubleValue) }
            return .integer(value.int64Value)
        case let values as [Any]:
            return .array(try values.map {
                try propertyListValue(
                    $0,
                    depth: depth + 1,
                    count: &count,
                    maximumValueCount: maximumValueCount
                )
            })
        case let values as [String: Any]:
            return .dictionary(try values.reduce(into: [String: PropertyListValue]()) { result, element in
                result[element.key] = try propertyListValue(
                    element.value,
                    depth: depth + 1,
                    count: &count,
                    maximumValueCount: maximumValueCount
                )
            })
        default:
            throw IPAError.inspectionFailure
        }
    }
}
