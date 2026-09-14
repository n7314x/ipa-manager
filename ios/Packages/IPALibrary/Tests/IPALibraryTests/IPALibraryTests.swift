import Foundation
import IPADomain
import IPAInspection
import XCTest
import ZIPFoundation
@testable import IPALibrary

@MainActor
final class IPALibraryTests: XCTestCase {
    func testArchivePolicyRejectsTraversal() {
        XCTAssertThrowsError(try ArchiveSafetyPolicy.default.validate([
            ArchiveEntryDescriptor(path: "Payload/../secret", compressedSize: 1, uncompressedSize: 1),
        ]))
    }

    func testPayloadRequiresOneTopLevelApp() throws {
        let app = try IPAValidator().validatePayloadPaths(["Payload/Demo.app/Info.plist"])
        XCTAssertEqual(app, "Payload/Demo.app")
    }

    func testLibraryLayoutCreatesDeterministicPaths() {
        let support = URL(fileURLWithPath: "/tmp/Application Support", isDirectory: true)
        let identifier = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let layout = LibraryFileLayout(applicationSupportURL: support)

        XCTAssertEqual(
            layout.originalIPA(for: identifier).path,
            "/tmp/Application Support/Library/AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE/original.ipa"
        )
        XCTAssertEqual(
            layout.originalRelativePath(for: identifier),
            "Library/AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE/original.ipa"
        )
    }

    func testSHA256UsesKnownFileBytes() throws {
        try withTemporaryDirectory { temporaryDirectory in
            let fileURL = temporaryDirectory.appending(path: "known.bin")
            try Data("hello".utf8).write(to: fileURL)

            XCTAssertEqual(
                try HashService().sha256(of: fileURL),
                "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
            )
        }
    }

    func testEmptyFileIsRejected() throws {
        try withTemporaryDirectory { temporaryDirectory in
            let fileURL = temporaryDirectory.appending(path: "Empty.ipa")
            try Data().write(to: fileURL)

            XCTAssertThrowsError(try IPAValidator().validateSource(at: fileURL)) { error in
                XCTAssertEqual(error as? IPAError, .invalidSource("the file is empty"))
            }
        }
    }

    func testOversizedPolicyUsesSmallFixture() throws {
        try withTemporaryDirectory { temporaryDirectory in
            let ipaURL = try makeSyntheticIPA(in: temporaryDirectory)
            let policy = ArchiveSafetyPolicy(maximumSourceIPABytes: 1)

            XCTAssertThrowsError(try IPAValidator().validateSource(at: ipaURL, policy: policy)) { error in
                XCTAssertEqual(error as? IPAError, .sourceTooLarge(maximumBytes: 1))
            }
        }
    }

    func testNonZIPFileIsRejectedAsUnsupportedArchive() throws {
        try withTemporaryDirectory { temporaryDirectory in
            let fileURL = temporaryDirectory.appending(path: "NotAnArchive.ipa")
            try Data("not a zip".utf8).write(to: fileURL)

            XCTAssertThrowsError(try IPAValidator().validateSource(at: fileURL)) { error in
                XCTAssertEqual(error as? IPAError, .unsupportedArchive)
            }
        }
    }

    func testImportCopiesIntoManagedLibraryAndLeavesSourceUnchanged() async throws {
        try await withTemporaryDirectory { temporaryDirectory in
            let sourceURL = try makeSyntheticIPA(in: temporaryDirectory)
            let sourceData = try Data(contentsOf: sourceURL)
            let repository = InMemoryLibraryRepository()
            let identifier = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
            let importDate = Date(timeIntervalSince1970: 1_700_000_000)
            let layout = LibraryFileLayout(applicationSupportURL: temporaryDirectory.appending(path: "support"))
            let service = IPALibraryService(
                layout: layout,
                repository: repository,
                inspector: deterministicInspector(),
                idGenerator: { identifier },
                dateProvider: { importDate }
            )

            let imported = try await service.importIPA(from: sourceURL)

            XCTAssertEqual(imported.id, identifier)
            XCTAssertEqual(imported.originalFilename, "Synthetic.ipa")
            XCTAssertEqual(imported.importedAt, importDate)
            XCTAssertEqual(imported.byteSize, Int64(sourceData.count))
            XCTAssertEqual(imported.sourceSHA256.count, 64)
            XCTAssertEqual(imported.inspectionStatus, .inspected)
            XCTAssertEqual(imported.inspection?.rootApplication.displayName, "Synthetic")
            XCTAssertEqual(imported.inspection?.rootApplication.bundleIdentifier, "example.synthetic")
            XCTAssertEqual(try Data(contentsOf: sourceURL), sourceData)
            XCTAssertEqual(try Data(contentsOf: layout.originalIPA(for: identifier)), sourceData)
            XCTAssertTrue(FileManager.default.fileExists(atPath: layout.metadataDirectory(for: identifier).path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: layout.artifactsDirectory(for: identifier).path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: layout.workDirectory(for: identifier).path))
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: layout.workDirectory(for: identifier).path), [])
            let attributes = try FileManager.default.attributesOfItem(atPath: layout.originalIPA(for: identifier).path)
            let permissions = attributes[.posixPermissions] as? NSNumber
            XCTAssertEqual(permissions?.intValue, 0o400)
            let savedItems = try await repository.listImportedIPAs()
            XCTAssertEqual(savedItems, [imported])
        }
    }

    func testDuplicateImportPreservesExistingItemAndCreatesNoSecondDirectory() async throws {
        try await withTemporaryDirectory { temporaryDirectory in
            let sourceURL = try makeSyntheticIPA(in: temporaryDirectory)
            let hash = try HashService().sha256(of: sourceURL)
            let existingID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
            let newID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
            let existing = ImportedIPA(
                id: existingID,
                originalFilename: "Existing.ipa",
                sourceSHA256: hash,
                originalRelativePath: "Library/\(existingID.uuidString)/original.ipa",
                byteSize: Int64(try Data(contentsOf: sourceURL).count)
            )
            let repository = InMemoryLibraryRepository(items: [existing])
            let layout = LibraryFileLayout(applicationSupportURL: temporaryDirectory.appending(path: "support"))
            let service = IPALibraryService(layout: layout, repository: repository, idGenerator: { newID })

            do {
                _ = try await service.importIPA(from: sourceURL)
                XCTFail("Expected duplicate import")
            } catch {
                XCTAssertEqual(error as? IPAError, .duplicateImport(existingID: existingID))
            }

            let remainingItems = try await repository.listImportedIPAs()
            XCTAssertEqual(remainingItems, [existing])
            XCTAssertFalse(FileManager.default.fileExists(atPath: layout.root(for: newID).path))
        }
    }

    func testPersistenceFailureCleansUpNewManagedDirectory() async throws {
        try await withTemporaryDirectory { temporaryDirectory in
            let sourceURL = try makeSyntheticIPA(in: temporaryDirectory)
            let repository = InMemoryLibraryRepository(failOnSave: true)
            let identifier = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
            let layout = LibraryFileLayout(applicationSupportURL: temporaryDirectory.appending(path: "support"))
            let service = IPALibraryService(layout: layout, repository: repository, idGenerator: { identifier })

            do {
                _ = try await service.importIPA(from: sourceURL)
                XCTFail("Expected persistence failure")
            } catch {
                guard let ipaError = error as? IPAError, case .persistenceFailure = ipaError else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }

            XCTAssertFalse(FileManager.default.fileExists(atPath: layout.root(for: identifier).path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
        }
    }

    func testIdentifierCollisionDoesNotRemoveExistingManagedDirectory() async throws {
        try await withTemporaryDirectory { temporaryDirectory in
            let sourceURL = try makeSyntheticIPA(in: temporaryDirectory)
            let repository = InMemoryLibraryRepository()
            let identifier = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
            let layout = LibraryFileLayout(applicationSupportURL: temporaryDirectory.appending(path: "support"))
            try FileManager.default.createDirectory(at: layout.libraryRoot, withIntermediateDirectories: true)
            try layout.createDirectories(for: identifier)
            let sentinelURL = layout.metadataDirectory(for: identifier).appending(path: "sentinel")
            try Data("keep".utf8).write(to: sentinelURL)
            let service = IPALibraryService(layout: layout, repository: repository, idGenerator: { identifier })

            do {
                _ = try await service.importIPA(from: sourceURL)
                XCTFail("Expected storage failure")
            } catch {
                guard let ipaError = error as? IPAError, case .storageFailure = ipaError else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }

            XCTAssertEqual(try Data(contentsOf: sentinelURL), Data("keep".utf8))
        }
    }

    func testDeletionRemovesManagedDirectoryAndMetadataButNotExternalSource() async throws {
        try await withTemporaryDirectory { temporaryDirectory in
            let sourceURL = try makeSyntheticIPA(in: temporaryDirectory)
            let repository = InMemoryLibraryRepository()
            let layout = LibraryFileLayout(applicationSupportURL: temporaryDirectory.appending(path: "support"))
            let service = IPALibraryService(
                layout: layout,
                repository: repository,
                inspector: deterministicInspector()
            )
            let imported = try await service.importIPA(from: sourceURL)

            try await service.removeImportedIPA(id: imported.id)

            XCTAssertFalse(FileManager.default.fileExists(atPath: layout.root(for: imported.id).path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
            let deletedItem = try await repository.importedIPA(id: imported.id)
            XCTAssertNil(deletedItem)
        }
    }

    func testDeletionRestoresManagedDirectoryWhenPersistenceFails() async throws {
        try await withTemporaryDirectory { temporaryDirectory in
            let sourceURL = try makeSyntheticIPA(in: temporaryDirectory)
            let repository = InMemoryLibraryRepository(failOnRemove: true)
            let layout = LibraryFileLayout(applicationSupportURL: temporaryDirectory.appending(path: "support"))
            let service = IPALibraryService(
                layout: layout,
                repository: repository,
                inspector: deterministicInspector()
            )
            let imported = try await service.importIPA(from: sourceURL)

            do {
                try await service.removeImportedIPA(id: imported.id)
                XCTFail("Expected persistence failure")
            } catch {
                guard let ipaError = error as? IPAError, case .persistenceFailure = ipaError else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }

            XCTAssertTrue(FileManager.default.fileExists(atPath: layout.root(for: imported.id).path))
            let preservedItem = try await repository.importedIPA(id: imported.id)
            XCTAssertEqual(preservedItem, imported)
        }
    }

    func testInspectionFailureKeepsManagedImportAndPersistsFailureState() async throws {
        try await withTemporaryDirectory { temporaryDirectory in
            let sourceFile = temporaryDirectory.appending(path: "resource")
            try Data("resource".utf8).write(to: sourceFile)
            let sourceURL = temporaryDirectory.appending(path: "Broken.ipa")
            do {
                let archive = try Archive(url: sourceURL, accessMode: .create)
                try archive.addEntry(with: "Payload/Broken.app/resource", fileURL: sourceFile)
            }

            let repository = InMemoryLibraryRepository()
            let layout = LibraryFileLayout(applicationSupportURL: temporaryDirectory.appending(path: "support"))
            let service = IPALibraryService(
                layout: layout,
                repository: repository,
                inspector: deterministicInspector()
            )

            let imported = try await service.importIPA(from: sourceURL)

            XCTAssertEqual(imported.inspectionStatus, .failed(.invalidStructure))
            XCTAssertNil(imported.inspection)
            XCTAssertTrue(FileManager.default.fileExists(atPath: layout.originalIPA(for: imported.id).path))
            let storedStatus = try await repository.importedIPA(id: imported.id)?.inspectionStatus
            XCTAssertEqual(storedStatus, .failed(.invalidStructure))
            XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
        }
    }

    func testLegacyImportIsInspectedLazilyAndHashBoundResultIsCached() async throws {
        try await withTemporaryDirectory { temporaryDirectory in
            let sourceURL = try makeSyntheticIPA(in: temporaryDirectory)
            let identifier = UUID()
            let hash = try HashService().sha256(of: sourceURL)
            let layout = LibraryFileLayout(applicationSupportURL: temporaryDirectory.appending(path: "support"))
            try FileManager.default.createDirectory(at: layout.libraryRoot, withIntermediateDirectories: true)
            try layout.createDirectories(for: identifier)
            try FileManager.default.copyItem(at: sourceURL, to: layout.originalIPA(for: identifier))
            let legacyItem = ImportedIPA(
                id: identifier,
                originalFilename: "Legacy.ipa",
                sourceSHA256: hash,
                originalRelativePath: layout.originalRelativePath(for: identifier),
                byteSize: Int64(try Data(contentsOf: sourceURL).count)
            )
            let repository = InMemoryLibraryRepository(items: [legacyItem])
            let inspector = RecordingInspector()
            let service = IPALibraryService(
                layout: layout,
                repository: repository,
                inspector: inspector
            )

            try await service.inspectPendingImportedIPAs()
            try await service.inspectPendingImportedIPAs()

            let restored = try await repository.importedIPA(id: identifier)
            XCTAssertEqual(restored?.inspectionStatus, .inspected)
            XCTAssertEqual(restored?.inspectionSourceSHA256, hash)
            XCTAssertEqual(restored?.inspection?.sourceSHA256, hash)
            let callCount = await inspector.callCount()
            XCTAssertEqual(callCount, 1)
        }
    }

    private func makeSyntheticIPA(in directory: URL) throws -> URL {
        let plistURL = directory.appending(path: "Info.plist")
        let plist = try PropertyListSerialization.data(
            fromPropertyList: [
                "CFBundleDisplayName": "Synthetic",
                "CFBundleIdentifier": "example.synthetic",
                "CFBundleShortVersionString": "1.0",
                "CFBundleVersion": "1",
            ],
            format: .binary,
            options: 0
        )
        try plist.write(to: plistURL)
        let ipaURL = directory.appending(path: "Synthetic.ipa")
        do {
            let archive = try Archive(url: ipaURL, accessMode: .create)
            try archive.addEntry(with: "Payload/Synthetic.app/Info.plist", fileURL: plistURL)
        }
        return ipaURL
    }

    private func deterministicInspector() -> IPAInspectionService {
        IPAInspectionService(
            capacityProvider: FixedInspectionStorageCapacityProvider(availableCapacity: .max)
        )
    }

    private func withTemporaryDirectory<T>(_ body: (URL) throws -> T) throws -> T {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "IPALibraryTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        return try body(directory)
    }

    private func withTemporaryDirectory<T>(_ body: (URL) async throws -> T) async throws -> T {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "IPALibraryTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        return try await body(directory)
    }
}

private struct FixedInspectionStorageCapacityProvider: InspectionStorageCapacityProviding {
    let availableCapacity: UInt64

    func availableCapacity(forVolumeContaining url: URL) throws -> UInt64 {
        availableCapacity
    }
}

private enum TestRepositoryError: Error {
    case forcedFailure
}

private actor InMemoryLibraryRepository: LibraryRepository {
    private var items: [ImportedIPA]
    private let failOnSave: Bool
    private let failOnRemove: Bool

    init(items: [ImportedIPA] = [], failOnSave: Bool = false, failOnRemove: Bool = false) {
        self.items = items
        self.failOnSave = failOnSave
        self.failOnRemove = failOnRemove
    }

    func listImportedIPAs() throws -> [ImportedIPA] {
        items.sorted { $0.importedAt > $1.importedAt }
    }

    func importedIPA(id: UUID) throws -> ImportedIPA? {
        items.first { $0.id == id }
    }

    func findBySHA256(_ sha256: String) throws -> ImportedIPA? {
        items.first { $0.sourceSHA256 == sha256 }
    }

    func save(_ importedIPA: ImportedIPA) throws {
        if failOnSave { throw TestRepositoryError.forcedFailure }
        items.append(importedIPA)
    }

    func updateInspection(
        id: UUID,
        status: InspectionStatus,
        sourceSHA256: String?,
        result: IPAInspectionResult?
    ) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw TestRepositoryError.forcedFailure
        }
        items[index].inspectionStatus = status
        items[index].inspectionSourceSHA256 = sourceSHA256
        items[index].inspection = result
    }

    func removeImportedIPA(id: UUID) throws {
        if failOnRemove { throw TestRepositoryError.forcedFailure }
        items.removeAll { $0.id == id }
    }
}

private actor RecordingInspector: IPAInspecting {
    private var calls = 0

    func inspect(_ request: IPAInspectionRequest) async throws -> IPAInspectionResult {
        calls += 1
        let app = AppBundleMetadata(
            displayName: "Legacy",
            bundleIdentifier: "example.legacy",
            relativePath: "Payload/Legacy.app"
        )
        return IPAInspectionResult(
            importedIPAID: request.importedIPAID,
            sourceSHA256: request.sourceSHA256,
            rootApplication: app,
            components: [BundleComponent(
                kind: .application,
                relativePath: app.relativePath,
                bundleIdentifier: app.bundleIdentifier,
                displayName: app.displayName
            )],
            provisioningProfile: nil
        )
    }

    func callCount() -> Int {
        calls
    }
}
