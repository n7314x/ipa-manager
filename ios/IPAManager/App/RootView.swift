import SwiftUI

struct RootView: View {
    @EnvironmentObject private var libraryViewModel: LibraryViewModel

    var body: some View {
        LibraryView(viewModel: libraryViewModel)
    }
}

#Preview {
    RootView()
        .environmentObject(LibraryViewModel(service: nil))
}
