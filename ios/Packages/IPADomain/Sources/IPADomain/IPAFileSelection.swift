import Foundation

public enum IPAFileSelection {
    public static func validate(_ url: URL) throws {
        guard url.pathExtension.caseInsensitiveCompare("ipa") == .orderedSame else {
            throw IPAError.invalidFileExtension
        }
    }
}
