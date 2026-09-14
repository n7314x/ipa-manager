import Foundation
import IPADomain
import SwiftUI
import UIKit

struct LibraryHeader: View {
    let itemCount: Int
    let isImporting: Bool
    let importAction: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize, itemCount > 0 {
                VStack(alignment: .leading, spacing: 16) {
                    identity
                    importButton
                }
            } else {
                HStack(alignment: .center, spacing: 16) {
                    identity
                    Spacer(minLength: 8)
                    if itemCount > 0 {
                        importButton
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.hairline)
                .frame(height: 0.5)
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("IPA Manager")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
            Text(itemCount == 0 ? "Your application library" : librarySummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var importButton: some View {
        Button(action: importAction) {
            Label(isImporting ? "Importing…" : "Import", systemImage: isImporting ? "hourglass" : "plus")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 3)
        }
        .adaptiveGlassButtonStyle()
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(AppColors.accent)
        .disabled(isImporting)
        .accessibilityLabel(isImporting ? "Importing IPA" : "Import IPA")
    }

    private var librarySummary: String {
        itemCount == 1 ? "1 imported IPA" : "\(itemCount) imported IPAs"
    }
}

struct LibraryEmptyState: View {
    let isImporting: Bool
    let importAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            IPAPackageIcon(size: 108)
                .padding(.bottom, 26)

            Text("Your library is empty")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            Text("Import an IPA to inspect and manage it securely on this device.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.top, 9)

            PrimaryActionButton(
                title: isImporting ? "Importing…" : "Import IPA",
                systemImage: "square.and.arrow.down",
                isWorking: isImporting,
                action: importAction
            )
            .padding(.top, 26)
        }
        .frame(maxWidth: 390)
        .padding(.horizontal, 26)
        .accessibilityElement(children: .contain)
    }
}

struct LibraryLoadingState: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(AppColors.accent)
            Text("Loading your library…")
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct LibrarySectionHeader: View {
    let count: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Imported IPAs")
                .font(.headline)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Text(count.formatted())
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .textCase(nil)
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
        .accessibilityElement(children: .combine)
    }
}

struct ImportedIPARow: View {
    let importedIPA: ImportedIPA

    var body: some View {
        GlassSurface(cornerRadius: 22, isInteractive: true) {
            HStack(alignment: .top, spacing: 14) {
                IPAPackageIcon(size: 54)

                VStack(alignment: .leading, spacing: 7) {
                    Text(importedIPA.originalFilename)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(fileSize) · \(importDescription)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 7) {
                            Text("SHA-256")
                                .fontWeight(.semibold)
                            Text(abbreviatedHash)
                                .monospaced()
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SHA-256")
                                .fontWeight(.semibold)
                            Text(abbreviatedHash)
                                .monospaced()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 19)
                    .accessibilityHidden(true)
            }
            .padding(16)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(importedIPA.originalFilename)
        .accessibilityValue("\(fileSize), \(importDescription), SHA-256 \(abbreviatedHash)")
        .accessibilityHint("Shows IPA details")
    }

    private var fileSize: String {
        ByteCountFormatter.string(fromByteCount: importedIPA.byteSize, countStyle: .file)
    }

    private var importDescription: String {
        if Calendar.current.isDateInToday(importedIPA.importedAt) {
            return "Imported today"
        }
        if Calendar.current.isDateInYesterday(importedIPA.importedAt) {
            return "Imported yesterday"
        }
        return "Imported \(importedIPA.importedAt.formatted(date: .abbreviated, time: .omitted))"
    }

    private var abbreviatedHash: String {
        guard importedIPA.sourceSHA256.count > 18 else { return importedIPA.sourceSHA256 }
        return "\(importedIPA.sourceSHA256.prefix(10))…\(importedIPA.sourceSHA256.suffix(6))"
    }
}

struct LibraryPrivacyNote: View {
    var body: some View {
        Label {
            Text("Imports stay in managed app storage. Your original file remains untouched.")
        } icon: {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(AppColors.accent)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

struct ImportProgressBanner: View {
    var body: some View {
        GlassSurface(cornerRadius: 18, tint: AppColors.accent.opacity(0.12)) {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(AppColors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Importing…")
                        .font(.callout.weight(.semibold))
                    Text("Preparing a managed copy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Importing IPA")
    }
}

struct ImportedIPADetailView: View {
    let importedIPA: ImportedIPA

    @Environment(\.dismiss) private var dismiss
    @State private var copyFeedbackToken = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 12) {
                            IPAPackageIcon(size: 82)
                            Text(importedIPA.originalFilename)
                                .font(.title3.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Label("Managed on this device", systemImage: "checkmark.shield.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppColors.accent)
                        }
                        .padding(.bottom, 4)

                        GlassSurface {
                            VStack(spacing: 0) {
                                DetailField(title: "Original filename", value: importedIPA.originalFilename)
                                divider
                                DetailField(title: "Size", value: fileSize)
                                divider
                                DetailField(title: "Imported", value: importDate)
                                divider
                                DetailField(title: "Status", value: "Managed copy")
                            }
                            .padding(.horizontal, 18)
                        }

                        GlassSurface {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("SHA-256")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(importedIPA.sourceSHA256)
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(.primary)
                                    .textSelection(.enabled)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button {
                                    UIPasteboard.general.string = importedIPA.sourceSHA256
                                    copyFeedbackToken &+= 1
                                } label: {
                                    Label("Copy SHA-256", systemImage: "doc.on.doc")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .adaptiveGlassButtonStyle()
                                .buttonBorderShape(.capsule)
                                .controlSize(.large)
                                .tint(AppColors.accent)
                                .accessibilityHint("Copies the complete hash")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("IPA Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(AppColors.accent)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.success, trigger: copyFeedbackToken)
    }

    private var divider: some View {
        Divider()
            .overlay(AppColors.hairline)
    }

    private var fileSize: String {
        ByteCountFormatter.string(fromByteCount: importedIPA.byteSize, countStyle: .file)
    }

    private var importDate: String {
        importedIPA.importedAt.formatted(date: .long, time: .shortened)
    }
}

private struct DetailField: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
    }
}
