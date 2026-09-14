import Foundation

public enum IPAError: Error, Codable, Equatable, Sendable {
    case invalidFileExtension
    case invalidSource(String)
    case inaccessibleSource
    case sourceTooLarge(maximumBytes: UInt64)
    case unsupportedArchive
    case duplicateImport(existingID: UUID)
    case hashingFailure
    case storageFailure(String)
    case persistenceFailure(String)
    case libraryItemNotFound
    case deletionFailure(String)
    case invalidArchive(String)
    case unsafeArchive(String)
    case archiveTooLarge(maximumBytes: UInt64)
    case archiveEntryTooLarge(maximumBytes: UInt64)
    case tooManyArchiveEntries(maximumCount: Int)
    case suspiciousCompressionRatio(maximumRatio: UInt64)
    case insufficientStorage(requiredBytes: UInt64)
    case duplicateArchiveEntry
    case invalidPayloadStructure
    case missingApplicationBundle
    case multipleRootApplications
    case missingInfoPlist
    case malformedInfoPlist
    case inspectionFailure
    case malformedMetadata(String)
    case incompatibleSigning(String)
    case nativeFailure(code: Int32, message: String)
    case unsupported(String)
}

extension IPAError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFileExtension:
            "Choose a file with the .ipa extension."
        case .invalidSource(let reason):
            "The selected file cannot be imported: \(reason)"
        case .inaccessibleSource:
            "IPA Manager could not access the selected file."
        case .sourceTooLarge(let maximumBytes):
            "The selected file exceeds the \(ByteCountFormatter.string(fromByteCount: Int64(clamping: maximumBytes), countStyle: .file)) import limit."
        case .unsupportedArchive:
            "The selected file is not a supported ZIP-based IPA archive."
        case .duplicateImport:
            "This IPA is already in the library."
        case .hashingFailure:
            "IPA Manager could not calculate the file's SHA-256."
        case .storageFailure(let reason):
            "IPA Manager could not store the IPA: \(reason)"
        case .persistenceFailure(let reason):
            "IPA Manager could not update the library: \(reason)"
        case .libraryItemNotFound:
            "The library item no longer exists."
        case .deletionFailure(let reason):
            "IPA Manager could not completely remove the item: \(reason)"
        case .invalidArchive(let reason):
            "The IPA archive is invalid: \(reason)"
        case .unsafeArchive(let reason):
            "The IPA archive was rejected: \(reason)"
        case .archiveTooLarge(let maximumBytes):
            "The IPA expands beyond the \(ByteCountFormatter.string(fromByteCount: Int64(clamping: maximumBytes), countStyle: .file)) safety limit."
        case .archiveEntryTooLarge(let maximumBytes):
            "An item in the IPA expands beyond the \(ByteCountFormatter.string(fromByteCount: Int64(clamping: maximumBytes), countStyle: .file)) safety limit."
        case .tooManyArchiveEntries(let maximumCount):
            "The IPA contains more than \(maximumCount) archive entries."
        case .suspiciousCompressionRatio(let maximumRatio):
            "The IPA contains an item compressed beyond the \(maximumRatio):1 safety limit."
        case .insufficientStorage:
            "IPA Manager needs more free space to inspect this IPA safely."
        case .duplicateArchiveEntry:
            "The IPA contains duplicate archive paths."
        case .invalidPayloadStructure:
            "The IPA has an unsupported Payload structure."
        case .missingApplicationBundle:
            "The IPA does not contain an application directly inside Payload."
        case .multipleRootApplications:
            "The IPA contains more than one application directly inside Payload."
        case .missingInfoPlist:
            "The application bundle does not contain an Info.plist."
        case .malformedInfoPlist:
            "The application Info.plist could not be read."
        case .inspectionFailure:
            "IPA Manager could not inspect this IPA."
        case .malformedMetadata(let reason):
            "The IPA metadata is malformed: \(reason)"
        case .incompatibleSigning(let reason):
            "The signing configuration is incompatible: \(reason)"
        case .nativeFailure:
            "A native operation failed."
        case .unsupported(let reason):
            "The operation is unsupported: \(reason)"
        }
    }
}
