import Foundation
import IPADomain

public actor IPALibraryService {
    private let layout: LibraryFileLayout
    private let repository: any LibraryRepository
    private let policy: ArchiveSafetyPolicy
    private let fileManager: FileManager
    private let idGenerator: @Sendable () -> UUID
    private let dateProvider: @Sendable () -> Date

    public init(
        layout: LibraryFileLayout,
        repository: any LibraryRepository,
        policy: ArchiveSafetyPolicy = .default,
        idGenerator: @escaping @Sendable () -> UUID = { UUID() },
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.layout = layout
        self.repository = repository
        self.policy = policy
        self.fileManager = FileManager()
        self.idGenerator = idGenerator
        self.dateProvider = dateProvider
    }

    public func importIPA(from sourceURL: URL) async throws -> ImportedIPA {
        let workspace: TemporaryWorkspace
        do {
            workspace = try TemporaryWorkspace(parent: layout.temporaryWorkspaceRoot, fileManager: fileManager)
        } catch {
            throw IPAError.storageFailure("a temporary import workspace could not be created")
        }

        let stagedURL = workspace.url.appending(path: "incoming.ipa")
        try IPAImporter(fileManager: fileManager).copyToTemporaryWorkspace(from: sourceURL, to: stagedURL)

        let byteSize = try IPAValidator().validateSource(at: stagedURL, policy: policy)
        let sha256: String
        do {
            sha256 = try HashService().sha256(of: stagedURL)
        } catch {
            throw IPAError.hashingFailure
        }

        do {
            if let existing = try await repository.findBySHA256(sha256) {
                throw IPAError.duplicateImport(existingID: existing.id)
            }
        } catch let error as IPAError {
            throw error
        } catch {
            throw IPAError.persistenceFailure("duplicate checking failed")
        }

        let id = idGenerator()
        let managedRoot = layout.root(for: id)
        var ownsManagedRoot = false
        do {
            try fileManager.createDirectory(at: layout.libraryRoot, withIntermediateDirectories: true)
            try layout.createDirectories(for: id, fileManager: fileManager)
            ownsManagedRoot = true
            try fileManager.copyItem(at: stagedURL, to: layout.originalIPA(for: id))
            try fileManager.setAttributes([.posixPermissions: 0o400], ofItemAtPath: layout.originalIPA(for: id).path)
        } catch {
            if ownsManagedRoot { try? fileManager.removeItem(at: managedRoot) }
            throw IPAError.storageFailure("the managed library directory could not be created")
        }

        let importedIPA = ImportedIPA(
            id: id,
            originalFilename: sourceURL.lastPathComponent,
            sourceSHA256: sha256,
            originalRelativePath: layout.originalRelativePath(for: id),
            byteSize: byteSize,
            importedAt: dateProvider()
        )
        do {
            try await repository.save(importedIPA)
        } catch {
            let existingAfterFailure: ImportedIPA?
            do {
                existingAfterFailure = try await repository.findBySHA256(sha256)
            } catch {
                existingAfterFailure = nil
            }
            if existingAfterFailure?.id == importedIPA.id {
                throw IPAError.persistenceFailure("the metadata save result could not be confirmed")
            }
            do {
                try fileManager.removeItem(at: managedRoot)
            } catch {
                throw IPAError.storageFailure("metadata saving failed and the new managed files could not be rolled back")
            }
            if let existing = existingAfterFailure {
                throw IPAError.duplicateImport(existingID: existing.id)
            }
            throw IPAError.persistenceFailure("the imported IPA metadata could not be saved")
        }
        return importedIPA
    }

    public func listImportedIPAs() async throws -> [ImportedIPA] {
        do {
            return try await repository.listImportedIPAs()
        } catch {
            throw IPAError.persistenceFailure("the library could not be loaded")
        }
    }

    public func importedIPA(id: UUID) async throws -> ImportedIPA? {
        do {
            return try await repository.importedIPA(id: id)
        } catch {
            throw IPAError.persistenceFailure("the library item could not be loaded")
        }
    }

    public func findBySHA256(_ sha256: String) async throws -> ImportedIPA? {
        do {
            return try await repository.findBySHA256(sha256)
        } catch {
            throw IPAError.persistenceFailure("the library could not be searched")
        }
    }

    public func removeImportedIPA(id: UUID) async throws {
        let item: ImportedIPA
        do {
            guard let existing = try await repository.importedIPA(id: id) else {
                throw IPAError.libraryItemNotFound
            }
            item = existing
        } catch let error as IPAError {
            throw error
        } catch {
            throw IPAError.persistenceFailure("the library item could not be loaded")
        }

        let managedRoot = layout.root(for: item.id)
        guard fileManager.fileExists(atPath: managedRoot.path) else {
            throw IPAError.deletionFailure("the managed library directory is missing; metadata was preserved")
        }

        let quarantineURL = layout.temporaryWorkspaceRoot.appending(
            path: "deleting-\(item.id.uuidString)-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        do {
            try fileManager.createDirectory(at: layout.temporaryWorkspaceRoot, withIntermediateDirectories: true)
            try fileManager.moveItem(at: managedRoot, to: quarantineURL)
        } catch {
            throw IPAError.deletionFailure("the managed files could not be prepared for deletion; metadata was preserved")
        }

        do {
            try await repository.removeImportedIPA(id: id)
        } catch {
            do {
                try fileManager.moveItem(at: quarantineURL, to: managedRoot)
            } catch {
                throw IPAError.deletionFailure("metadata deletion failed and the managed directory could not be restored")
            }
            throw IPAError.persistenceFailure("the library metadata could not be deleted; managed files were restored")
        }

        do {
            try fileManager.removeItem(at: quarantineURL)
        } catch {
            throw IPAError.deletionFailure("metadata was deleted, but managed files still require cleanup")
        }
    }
}
