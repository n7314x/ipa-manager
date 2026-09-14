import Combine
import Foundation
import IPADomain
import IPALibrary

@MainActor
final class LibraryViewModel: ObservableObject {
    struct PresentedError: Identifiable {
        let id = UUID()
        let title: String
        let message: String

        init(error: Error) {
            guard let ipaError = error as? IPAError else {
                title = "Something Went Wrong"
                message = "The operation could not be completed. Please try again."
                return
            }

            switch ipaError {
            case .invalidFileExtension:
                title = "Not an IPA"
                message = "Choose a file with the .ipa extension."
            case .duplicateImport:
                title = "Already in Library"
                message = "This IPA has already been imported."
            case .unsafeArchive, .duplicateArchiveEntry, .suspiciousCompressionRatio:
                title = "Unsafe IPA"
                message = "This archive contains content that cannot be extracted safely."
            case .unsupportedArchive, .invalidArchive, .invalidSource,
                 .invalidPayloadStructure, .missingApplicationBundle,
                 .multipleRootApplications, .missingInfoPlist, .malformedInfoPlist:
                title = "Invalid IPA"
                message = "The archive does not contain a valid application in Payload."
            case .sourceTooLarge(let maximumBytes):
                title = "IPA Is Too Large"
                let limit = ByteCountFormatter.string(
                    fromByteCount: Int64(clamping: maximumBytes),
                    countStyle: .file
                )
                message = "The selected file exceeds the \(limit) import limit."
            case .archiveTooLarge(let maximumBytes), .archiveEntryTooLarge(let maximumBytes):
                title = "IPA Too Large"
                let limit = ByteCountFormatter.string(
                    fromByteCount: Int64(clamping: maximumBytes),
                    countStyle: .file
                )
                message = "This archive expands beyond IPA Manager’s \(limit) safety limit."
            case .tooManyArchiveEntries(let maximumCount):
                title = "IPA Too Complex"
                message = "This archive contains more than \(maximumCount) items and cannot be inspected safely."
            case .insufficientStorage:
                title = "Not Enough Storage"
                message = "IPA Manager needs more free space to inspect this IPA safely."
            case .inaccessibleSource:
                title = "File Unavailable"
                message = "IPA Manager could not read the selected file. Make sure it is downloaded and try again."
            case .hashingFailure:
                title = "Couldn’t Verify IPA"
                message = "IPA Manager could not verify the selected file. The library was not changed."
            case .storageFailure:
                title = "Couldn’t Store IPA"
                message = "The IPA could not be stored on this device. Check available storage and try again."
            case .persistenceFailure:
                title = "Library Unavailable"
                message = "IPA Manager could not update its library. Please try again."
            case .libraryItemNotFound, .deletionFailure:
                title = "Couldn’t Remove IPA"
                message = "The managed copy could not be removed completely. Please try again."
            case .inspectionFailure, .malformedMetadata, .incompatibleSigning, .nativeFailure, .unsupported:
                title = "Operation Failed"
                message = "The operation could not be completed. Please try again."
            }
        }
    }

    @Published private(set) var importedIPAs: [ImportedIPA] = []
    @Published private(set) var isImporting = false
    @Published private(set) var isLoading = false
    @Published private(set) var isInspecting = false
    @Published private(set) var successFeedbackToken = 0
    @Published var isFileImporterPresented = false
    @Published var presentedError: PresentedError?
    @Published var pendingDeletion: ImportedIPA?

    private let service: IPALibraryService?
    private var hasLoaded = false

    init(service: IPALibraryService?, startupError: IPAError? = nil) {
        self.service = service
        if let startupError {
            self.presentedError = PresentedError(error: startupError)
        }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await reloadLibrary()
        startLazyInspectionIfNeeded()
    }

    func importSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try IPAFileSelection.validate(url)
                importIPA(from: url)
            } catch {
                present(error)
            }
        case .failure(let error):
            if let cocoaError = error as? CocoaError, cocoaError.code == .userCancelled { return }
            present(IPAError.inaccessibleSource)
        }
    }

    func requestDeletion(of importedIPA: ImportedIPA) {
        pendingDeletion = importedIPA
    }

    func confirmDeletion() {
        guard let importedIPA = pendingDeletion else { return }
        pendingDeletion = nil
        guard let service else {
            present(IPAError.persistenceFailure("library services are unavailable"))
            return
        }
        Task {
            do {
                try await service.removeImportedIPA(id: importedIPA.id)
                successFeedbackToken &+= 1
            } catch {
                present(error)
            }
            await reloadLibrary()
            startLazyInspectionIfNeeded()
        }
    }

    private func importIPA(from url: URL) {
        guard let service else {
            present(IPAError.persistenceFailure("library services are unavailable"))
            return
        }
        guard !isImporting else { return }
        isImporting = true
        Task {
            defer { isImporting = false }
            do {
                _ = try await service.importIPA(from: url)
                successFeedbackToken &+= 1
            } catch {
                present(error)
            }
            await reloadLibrary()
            startLazyInspectionIfNeeded()
        }
    }

    private func reloadLibrary() async {
        guard let service else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            importedIPAs = try await service.listImportedIPAs()
        } catch {
            present(error)
        }
    }

    private func startLazyInspectionIfNeeded() {
        guard !isInspecting,
              importedIPAs.contains(where: { $0.needsInspection }),
              let service
        else { return }

        isInspecting = true
        importedIPAs = importedIPAs.map { item in
            guard item.needsInspection else { return item }
            var inspectingItem = item
            inspectingItem.inspectionStatus = .inspecting
            return inspectingItem
        }
        Task { [weak self] in
            do {
                try await service.inspectPendingImportedIPAs()
            } catch {
                self?.present(error)
            }
            await self?.reloadLibrary()
            self?.isInspecting = false
        }
    }

    private func present(_ error: Error) {
        presentedError = PresentedError(error: error)
    }
}
