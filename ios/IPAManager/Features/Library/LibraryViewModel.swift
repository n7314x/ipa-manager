import Combine
import Foundation
import IPADomain
import IPALibrary

@MainActor
final class LibraryViewModel: ObservableObject {
    struct PresentedError: Identifiable {
        let id = UUID()
        let message: String
    }

    @Published private(set) var importedIPAs: [ImportedIPA] = []
    @Published private(set) var isImporting = false
    @Published private(set) var isLoading = false
    @Published var isFileImporterPresented = false
    @Published var presentedError: PresentedError?
    @Published var pendingDeletion: ImportedIPA?

    private let service: IPALibraryService?
    private var hasLoaded = false

    init(service: IPALibraryService?, startupError: IPAError? = nil) {
        self.service = service
        if let startupError {
            self.presentedError = PresentedError(message: startupError.localizedDescription)
        }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await reloadLibrary()
    }

    func importSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                present(IPAError.invalidSource("no file was selected"))
                return
            }
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
        guard let importedIPA = pendingDeletion, let service else { return }
        pendingDeletion = nil
        Task {
            do {
                try await service.removeImportedIPA(id: importedIPA.id)
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
        let message: String
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            message = description
        } else {
            message = "The operation could not be completed."
        }
        presentedError = PresentedError(message: message)
    }
}
