import IPADomain
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @ObservedObject var viewModel: LibraryViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedIPA: ImportedIPA?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    LibraryHeader(
                        itemCount: viewModel.importedIPAs.count,
                        isImporting: viewModel.isImporting,
                        importAction: presentFileImporter
                    )

                    libraryContent
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if viewModel.isImporting {
                    ImportProgressBanner()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .tint(AppColors.accent)
        .task { await viewModel.loadIfNeeded() }
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: [.data],
            onCompletion: { result in viewModel.importSelection(result) }
        )
        .sheet(item: $selectedIPA) { importedIPA in
            ImportedIPADetailView(importedIPA: importedIPA)
        }
        .alert(item: $viewModel.presentedError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            deletionTitle,
            isPresented: Binding(
                get: { viewModel.pendingDeletion != nil },
                set: { if !$0 { viewModel.pendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove IPA", role: .destructive) {
                viewModel.confirmDeletion()
            }
            Button("Cancel", role: .cancel) {
                viewModel.pendingDeletion = nil
            }
        } message: {
            Text("The managed copy and its library record will be removed. Your original file will not be changed.")
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: viewModel.importedIPAs)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.20), value: viewModel.isImporting)
        .sensoryFeedback(.success, trigger: viewModel.successFeedbackToken)
    }

    @ViewBuilder
    private var libraryContent: some View {
        if viewModel.importedIPAs.isEmpty, viewModel.isLoading {
            centeredScrollableContent {
                LibraryLoadingState()
            }
            .transition(.opacity)
        } else if viewModel.importedIPAs.isEmpty {
            centeredScrollableContent {
                LibraryEmptyState(
                    isImporting: viewModel.isImporting,
                    importAction: presentFileImporter
                )
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            importedIPAList
                .transition(.opacity)
        }
    }

    private var importedIPAList: some View {
        List {
            Section {
                ForEach(viewModel.importedIPAs) { importedIPA in
                    Button {
                        selectedIPA = importedIPA
                    } label: {
                        ImportedIPARow(importedIPA: importedIPA)
                    }
                    .buttonStyle(PressableCardButtonStyle())
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Remove", systemImage: "trash", role: .destructive) {
                            viewModel.requestDeletion(of: importedIPA)
                        }
                    }
                    .contextMenu {
                        Button("Remove from Library", systemImage: "trash", role: .destructive) {
                            viewModel.requestDeletion(of: importedIPA)
                        }
                    }
                }
            } header: {
                LibrarySectionHeader(count: viewModel.importedIPAs.count)
                    .padding(.horizontal, 16)
            }

            Section {
                LibraryPrivacyNote()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 14)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
    }

    private func centeredScrollableContent<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let builtContent = content()

        return GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 28)
                    builtContent
                    Spacer(minLength: 28)
                    LibraryPrivacyNote()
                        .frame(maxWidth: 390)
                        .padding(.horizontal, 28)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func presentFileImporter() {
        guard !viewModel.isImporting else { return }
        viewModel.isFileImporterPresented = true
    }

    private var deletionTitle: String {
        guard let pendingDeletion = viewModel.pendingDeletion else { return "Remove this IPA?" }
        return "Remove \(pendingDeletion.originalFilename)?"
    }
}
