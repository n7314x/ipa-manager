import Foundation
import IPADomain
import SwiftData

@ModelActor
public actor ImportedIPAStore {
    public func listImportedIPAs() throws -> [ImportedIPA] {
        let descriptor = FetchDescriptor<ImportedIPAEntity>(
            sortBy: [SortDescriptor(\.importedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(\.domainModel)
    }

    public func importedIPA(id: UUID) throws -> ImportedIPA? {
        let identifier = id
        var descriptor = FetchDescriptor<ImportedIPAEntity>(
            predicate: #Predicate { $0.id == identifier }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.domainModel
    }

    public func findBySHA256(_ sha256: String) throws -> ImportedIPA? {
        let sourceHash = sha256
        var descriptor = FetchDescriptor<ImportedIPAEntity>(
            predicate: #Predicate { $0.sourceSHA256 == sourceHash }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.domainModel
    }

    public func save(_ importedIPA: ImportedIPA) throws {
        modelContext.insert(ImportedIPAEntity(importedIPA: importedIPA))
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func updateInspection(
        id: UUID,
        status: InspectionStatus,
        sourceSHA256: String?,
        result: IPAInspectionResult?
    ) throws {
        let identifier = id
        var descriptor = FetchDescriptor<ImportedIPAEntity>(
            predicate: #Predicate { $0.id == identifier }
        )
        descriptor.fetchLimit = 1
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        let obsoleteComponents = entity.inspectionComponents
        entity.applyInspection(status: status, sourceSHA256: sourceSHA256, result: result)
        for component in obsoleteComponents { modelContext.delete(component) }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func removeImportedIPA(id: UUID) throws {
        let identifier = id
        var descriptor = FetchDescriptor<ImportedIPAEntity>(
            predicate: #Predicate { $0.id == identifier }
        )
        descriptor.fetchLimit = 1
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
