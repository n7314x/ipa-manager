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
            case .duplicateImport:
                title = "Already in Library"
                message = "This IPA has already been imported."
            case .unsupportedArchive, .invalidArchive, .unsafeArchive, .invalidSource:
                title = "Unsupported IPA"
                message = "Choose a valid .ipa archive that contains a single application."
            case .sourceTooLarge(let maximumBytes):
                title = "IPA Is Too Large"
                let limit = ByteCountFormatter.string(
                    fromByteCount: Int64(clamping: maximumBytes),
                    countStyle: .file
                )
                message = "The selected file exceeds the \(limit) import limit."
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
            case .malformedMetadata, .incompatibleSigning, .nativeFailure, .unsupported:
                title = "Operation Failed"
                message = "The operation could not be completed. Please try again."
            }
        }
    }

    @Published private(set) var importedIPAs: [ImportedIPA] = []
    @Published private(set) var isImporting = false
    @Published private(set) var isLoading = false
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
    }

    func importSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            importIPA(from: url)
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

    private func present(_ error: Error) {
        presentedError = PresentedError(error: error)
    }
}
