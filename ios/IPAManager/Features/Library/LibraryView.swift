import Foundation
import IPADomain
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @ObservedObject var viewModel: LibraryViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.importedIPAs.isEmpty, viewModel.isLoading {
                    ProgressView("Loading library…")
                } else if viewModel.importedIPAs.isEmpty {
                    ContentUnavailableView {
                        Label("No Imported IPAs", systemImage: "shippingbox")
                    } description: {
                        Text("Import an IPA to keep an immutable managed copy in your library.")
                    } actions: {
                        Button("Import IPA", systemImage: "square.and.arrow.down") {
                            viewModel.isFileImporterPresented = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isImporting)
                    }
                } else {
                    List(viewModel.importedIPAs) { importedIPA in
                        NavigationLink {
                            ImportedIPADetailView(importedIPA: importedIPA)
                        } label: {
                            ImportedIPARow(importedIPA: importedIPA)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Remove", systemImage: "trash", role: .destructive) {
                                viewModel.requestDeletion(of: importedIPA)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Import IPA", systemImage: "plus") {
                        viewModel.isFileImporterPresented = true
                    }
                    .disabled(viewModel.isImporting)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.isImporting {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Importing IPA…")
                            .font(.callout.weight(.medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 8)
                }
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: [.ipaArchive],
            allowsMultipleSelection: false,
            onCompletion: { result in viewModel.importSelection(result) }
        )
        .alert(item: $viewModel.presentedError) { error in
            Alert(
                title: Text("IPA Manager"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            "Remove this IPA?",
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
            Text("The managed IPA and its library metadata will be deleted. The original file you selected will not be changed.")
        }
    }
}

private struct ImportedIPARow: View {
    let importedIPA: ImportedIPA

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(displayName)
                .font(.headline)
                .lineLimit(1)
            Text(importedIPA.originalFilename)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack {
                Text(ByteCountFormatter.string(fromByteCount: importedIPA.byteSize, countStyle: .file))
                Text(importedIPA.importedAt.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Text("SHA-256 \(importedIPA.sourceSHA256.prefix(12))…")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var displayName: String {
        let stem = (importedIPA.originalFilename as NSString).deletingPathExtension
        return stem.isEmpty ? importedIPA.originalFilename : stem
    }
}

private struct ImportedIPADetailView: View {
    let importedIPA: ImportedIPA

    var body: some View {
        List {
            Section("File") {
                LabeledContent("Filename", value: importedIPA.originalFilename)
                LabeledContent(
                    "Size",
                    value: ByteCountFormatter.string(fromByteCount: importedIPA.byteSize, countStyle: .file)
                )
                LabeledContent(
                    "Imported",
                    value: importedIPA.importedAt.formatted(date: .long, time: .shortened)
                )
            }
            Section("SHA-256") {
                Text(importedIPA.sourceSHA256)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            }
        }
        .navigationTitle((importedIPA.originalFilename as NSString).deletingPathExtension)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension UTType {
    static let ipaArchive = UTType(filenameExtension: "ipa", conformingTo: .zip) ?? .zip
}
