import Foundation
import IPADomain

public struct RefreshVerification: Equatable, Sendable {
    public let oldExpiry: Date
    public let installedExpiry: Date
    public var succeeded: Bool { installedExpiry > oldExpiry }

    public init(oldExpiry: Date, installedExpiry: Date) {
        self.oldExpiry = oldExpiry
        self.installedExpiry = installedExpiry
    }
}
