import IPADomain
import SwiftUI

@main
struct IPAManagerApp: App {
    private let appContainer: AppContainer?
    @StateObject private var libraryViewModel: LibraryViewModel

    init() {
        do {
            let container = try AppContainer()
            appContainer = container
            _libraryViewModel = StateObject(wrappedValue: LibraryViewModel(service: container.libraryService))
        } catch {
            appContainer = nil
            _libraryViewModel = StateObject(wrappedValue: LibraryViewModel(
                service: nil,
                startupError: .persistenceFailure("library services could not be initialized")
            ))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(libraryViewModel)
        }
    }
}
