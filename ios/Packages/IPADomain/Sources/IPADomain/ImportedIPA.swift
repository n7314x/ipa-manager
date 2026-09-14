import Foundation

public struct ImportedIPA: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let originalFilename: String
    public let sourceSHA256: String
    public let originalRelativePath: String
    public let byteSize: Int64
    public let importedAt: Date
    public var app: AppBundle?
    public var inspectionStatus: InspectionStatus
    public var inspectionSourceSHA256: String?
    public var inspection: IPAInspectionResult?

    public init(
        id: UUID = UUID(),
        originalFilename: String,
        sourceSHA256: String,
        originalRelativePath: String,
        byteSize: Int64,
        importedAt: Date = Date(),
        app: AppBundle? = nil,
        inspectionStatus: InspectionStatus = .notInspected,
        inspectionSourceSHA256: String? = nil,
        inspection: IPAInspectionResult? = nil
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.sourceSHA256 = sourceSHA256
        self.originalRelativePath = originalRelativePath
        self.byteSize = byteSize
        self.importedAt = importedAt
        self.app = app
        self.inspectionStatus = inspectionStatus
        self.inspectionSourceSHA256 = inspectionSourceSHA256
        self.inspection = inspection
    }

    public var needsInspection: Bool {
        guard inspectionSourceSHA256 == sourceSHA256 else { return true }
        switch inspectionStatus {
        case .notInspected, .inspecting:
            return true
        case .inspected:
            return inspection?.sourceSHA256 != sourceSHA256
                || inspection?.formatVersion != IPAInspectionResult.currentFormatVersion
        case .failed(let reason):
            return reason == .invalidCache
        }
    }
}
