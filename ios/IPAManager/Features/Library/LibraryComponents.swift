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
            HStack(alignment: .center, spacing: 14) {
                ImportedIPAIcon(importedIPA: importedIPA, size: 54)

                VStack(alignment: .leading, spacing: 5) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let bundleIdentifier {
                        Text(bundleIdentifier)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text(statusLine)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(16)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(displayName)
        .accessibilityValue([bundleIdentifier, statusLine].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Shows IPA details")
    }

    private var fileSize: String {
        ByteCountFormatter.string(fromByteCount: importedIPA.byteSize, countStyle: .file)
    }

    private var displayName: String {
        importedIPA.inspection?.rootApplication.displayName ?? importedIPA.originalFilename
    }

    private var bundleIdentifier: String? {
        importedIPA.inspection?.rootApplication.bundleIdentifier
    }

    private var statusLine: String {
        switch importedIPA.inspectionStatus {
        case .notInspected:
            return "Waiting for inspection…"
        case .inspecting:
            return "Inspecting…"
        case .failed:
            return "Couldn’t inspect IPA"
        case .inspected:
            let version = importedIPA.inspection?.rootApplication.shortVersion.map { "Version \($0)" }
            return [fileSize, version].compactMap { $0 }.joined(separator: " · ")
        }
    }

    private var statusColor: Color {
        if case .failed = importedIPA.inspectionStatus { return .orange }
        return .secondary
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
                    Text("Creating a managed copy and inspecting it safely")
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
                            ImportedIPAIcon(importedIPA: importedIPA, size: 82)
                            Text(displayName)
                                .font(.title3.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            if let bundleIdentifier = app?.bundleIdentifier {
                                Text(bundleIdentifier)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                            Label(inspectionLabel, systemImage: inspectionSymbol)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(inspectionColor)
                        }
                        .padding(.bottom, 4)

                        DetailSectionCard(title: "Application") {
                            VStack(spacing: 0) {
                                ForEach(Array(applicationFields.enumerated()), id: \.offset) { index, field in
                                    if index > 0 { detailDivider }
                                    DetailField(title: field.title, value: field.value)
                                }
                            }
                            .padding(.horizontal, 18)
                        }

                        if let components = importedIPA.inspection?.components, !components.isEmpty {
                            DetailSectionCard(title: "Components", subtitle: componentSummary(components)) {
                                VStack(spacing: 0) {
                                    ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                                        if index > 0 { detailDivider }
                                        ComponentDetailRow(component: component)
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }

                        if importedIPA.inspection != nil {
                            DetailSectionCard(title: "Provisioning") {
                                VStack(spacing: 0) {
                                    ForEach(Array(provisioningFields.enumerated()), id: \.offset) { index, field in
                                        if index > 0 { detailDivider }
                                        DetailField(title: field.title, value: field.value)
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }

                        DetailSectionCard(title: "Integrity") {
                            VStack(alignment: .leading, spacing: 14) {
                                DetailField(title: "Imported", value: importDate)
                                if let inspectedAt = importedIPA.inspection?.inspectedAt {
                                    detailDivider
                                    DetailField(
                                        title: "Inspected",
                                        value: inspectedAt.formatted(date: .long, time: .shortened)
                                    )
                                }
                                detailDivider
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
                            .padding(.horizontal, 18)
                            .padding(.bottom, 18)
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

    private var detailDivider: some View {
        Divider()
            .overlay(AppColors.hairline)
    }

    private var app: AppBundleMetadata? {
        importedIPA.inspection?.rootApplication
    }

    private var displayName: String {
        app?.displayName ?? importedIPA.originalFilename
    }

    private var inspectionLabel: String {
        switch importedIPA.inspectionStatus {
        case .notInspected: "Waiting for inspection"
        case .inspecting: "Inspecting securely"
        case .inspected: "Inspection complete"
        case .failed: "Couldn’t inspect IPA"
        }
    }

    private var inspectionSymbol: String {
        switch importedIPA.inspectionStatus {
        case .notInspected: "clock"
        case .inspecting: "hourglass"
        case .inspected: "checkmark.shield.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var inspectionColor: Color {
        if case .failed = importedIPA.inspectionStatus { return .orange }
        return AppColors.accent
    }

    private var applicationFields: [DetailValue] {
        var fields: [DetailValue] = []
        if let app {
            fields.append(DetailValue(title: "Name", value: app.displayName))
            append(app.bundleIdentifier, title: "Bundle ID", to: &fields)
            append(app.shortVersion, title: "Version", to: &fields)
            append(app.buildVersion, title: "Build", to: &fields)
            append(app.minimumOSVersion, title: "Minimum iOS", to: &fields)
            append(app.executableName, title: "Executable", to: &fields)
            append(app.packageType, title: "Package type", to: &fields)
            append(app.platformName, title: "Platform", to: &fields)
            append(app.platformVersion, title: "Platform version", to: &fields)
            append(app.sdkName, title: "SDK", to: &fields)
            if !app.deviceFamilies.isEmpty {
                fields.append(DetailValue(
                    title: "Device families",
                    value: app.deviceFamilies.map(String.init).joined(separator: ", ")
                ))
            }
            fields.append(DetailValue(title: "Main application", value: app.relativePath))
        }
        fields.append(DetailValue(title: "Original filename", value: importedIPA.originalFilename))
        fields.append(DetailValue(title: "Size", value: fileSize))
        return fields
    }

    private var provisioningFields: [DetailValue] {
        guard let profile = importedIPA.inspection?.provisioningProfile else {
            return [DetailValue(title: "Embedded profile", value: "No")]
        }
        var fields = [DetailValue(title: "Embedded profile", value: "Yes")]
        if profile.decodeStatus == .unavailable {
            fields.append(DetailValue(title: "Profile metadata", value: "Unavailable"))
            return fields
        }
        append(profile.name, title: "Profile name", to: &fields)
        append(profile.profileUUID, title: "UUID", to: &fields)
        append(profile.teamName, title: "Team", to: &fields)
        if !profile.teamIdentifiers.isEmpty {
            fields.append(DetailValue(title: "Team identifiers", value: profile.teamIdentifiers.joined(separator: ", ")))
        }
        if !profile.applicationIdentifierPrefixes.isEmpty {
            fields.append(DetailValue(
                title: "Application identifier prefixes",
                value: profile.applicationIdentifierPrefixes.joined(separator: ", ")
            ))
        }
        if let date = profile.creationDate {
            fields.append(DetailValue(title: "Created", value: date.formatted(date: .abbreviated, time: .shortened)))
        }
        if let date = profile.expirationDate {
            fields.append(DetailValue(title: "Expires", value: date.formatted(date: .abbreviated, time: .shortened)))
        }
        if let count = profile.provisionedDevicesCount {
            fields.append(DetailValue(title: "Provisioned devices", value: count.formatted()))
        }
        if let allDevices = profile.provisionsAllDevices {
            fields.append(DetailValue(title: "Provisions all devices", value: allDevices ? "Yes" : "No"))
        }
        if let entitlements = profile.entitlements {
            fields.append(DetailValue(title: "Profile entitlements", value: entitlements.count.formatted()))
        }
        return fields
    }

    private func append(_ value: String?, title: String, to fields: inout [DetailValue]) {
        guard let value, !value.isEmpty else { return }
        fields.append(DetailValue(title: title, value: value))
    }

    private func componentSummary(_ components: [BundleComponent]) -> String {
        let extensions = components.filter { $0.kind == .extensionBundle }.count
        let frameworks = components.filter { $0.kind == .framework }.count
        let nestedApps = components.filter { $0.kind == .nestedApplication }.count
        var summaries = ["Main app"]
        if extensions > 0 { summaries.append("\(extensions) extension\(extensions == 1 ? "" : "s")") }
        if frameworks > 0 { summaries.append("\(frameworks) framework\(frameworks == 1 ? "" : "s")") }
        if nestedApps > 0 { summaries.append("\(nestedApps) nested app\(nestedApps == 1 ? "" : "s")") }
        return summaries.joined(separator: " · ")
    }

    private var fileSize: String {
        ByteCountFormatter.string(fromByteCount: importedIPA.byteSize, countStyle: .file)
    }

    private var importDate: String {
        importedIPA.importedAt.formatted(date: .long, time: .shortened)
    }
}

private struct DetailValue {
    let title: String
    let value: String
}

private struct DetailSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 6)
                content
            }
        }
    }
}

private struct ComponentDetailRow: View {
    let component: BundleComponent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(component.displayName ?? typeName)
                .font(.body.weight(.medium))
            if component.displayName != nil {
                Text(typeName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let bundleIdentifier = component.bundleIdentifier {
                Text(bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            if let versionLine {
                Text(versionLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(component.relativePath)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }

    private var typeName: String {
        switch component.kind {
        case .application: "Main application"
        case .extensionBundle: "App extension"
        case .framework: "Framework"
        case .nestedApplication: "Nested application"
        case .dylib: "Dynamic library"
        }
    }

    private var versionLine: String? {
        let version = component.version.map { "Version \($0)" }
        let build = component.buildVersion.map { "Build \($0)" }
        let values = [version, build].compactMap { $0 }
        return values.isEmpty ? nil : values.joined(separator: " · ")
    }
}

private struct DetailField: View {
    let title: String
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
