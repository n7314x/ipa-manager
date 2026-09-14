import IPADomain
import IPAInspection
import SwiftUI
import UIKit

enum AppColors {
    static let accent = Color(uiColor: .systemBlue)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let accentWash = accent.opacity(0.12)
    static let surfaceTint = accent.opacity(0.08)
    static let hairline = Color.primary.opacity(0.10)
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppColors.background
            RadialGradient(
                colors: [
                    AppColors.accent.opacity(colorScheme == .dark ? 0.16 : 0.08),
                    .clear,
                ],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 430
            )
        }
        .ignoresSafeArea()
    }
}

struct GlassSurface<Content: View>: View {
    private let cornerRadius: CGFloat
    private let tint: Color?
    private let isInteractive: Bool
    private let content: Content

    init(
        cornerRadius: CGFloat = 22,
        tint: Color? = AppColors.surfaceTint,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.isInteractive = isInteractive
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .adaptiveGlassSurface(tint: tint, isInteractive: isInteractive, in: shape)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
    }
}

struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

struct PrimaryActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    var isWorking = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: systemImage)
                        .fontWeight(.semibold)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
        }
        .adaptiveProminentGlassButtonStyle()
        .buttonBorderShape(.roundedRectangle(radius: 15))
        .controlSize(.large)
        .tint(AppColors.accent)
        .disabled(isWorking)
    }
}

struct IPAPackageIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(AppColors.accentWash)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                        .strokeBorder(AppColors.accent.opacity(0.18), lineWidth: 1)
                }

            PackageGlyph()
                .frame(width: size * 0.58, height: size * 0.58)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct ImportedIPAIcon: View {
    let importedIPA: ImportedIPA
    let size: CGFloat

    @State private var cachedImage: UIImage?

    var body: some View {
        Group {
            if let cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
                    }
            } else {
                IPAPackageIcon(size: size)
            }
        }
        .frame(width: size, height: size)
        .task(id: importedIPA.inspection?.rootApplication.icon?.relativePath) {
            cachedImage = loadManagedIcon()
        }
        .accessibilityHidden(true)
    }

    private func loadManagedIcon() -> UIImage? {
        guard let relativePath = importedIPA.inspection?.rootApplication.icon?.relativePath,
              relativePath == "Library/\(importedIPA.id.uuidString)/metadata/app-icon.png",
              !relativePath.hasPrefix("/"),
              !relativePath.contains("\\")
        else { return nil }
        let components = relativePath.split(separator: "/", omittingEmptySubsequences: false)
        guard !components.isEmpty,
              !components.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." })
        else { return nil }

        let fileManager = FileManager()
        guard let supportURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return nil }
        let candidate = components.reduce(supportURL.standardizedFileURL) { partial, component in
            partial.appending(path: String(component))
        }.standardizedFileURL
        let rootComponents = supportURL.standardizedFileURL.pathComponents
        let candidateComponents = candidate.pathComponents
        guard candidateComponents.count > rootComponents.count,
              candidateComponents.prefix(rootComponents.count).elementsEqual(rootComponents),
              candidate.pathExtension.lowercased() == "png",
              let values = try? candidate.resourceValues(forKeys: [
                .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey,
              ]),
              values.isRegularFile == true,
              values.isSymbolicLink != true,
              let size = values.fileSize,
              size > 0,
              UInt64(size) <= ArchiveSafetyPolicy.default.maximumIconBytes
        else { return nil }
        return UIImage(contentsOfFile: candidate.path)
    }
}

private struct PackageGlyph: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                path([
                    point(0.50, 0.38, in: size),
                    point(0.86, 0.56, in: size),
                    point(0.50, 0.75, in: size),
                    point(0.14, 0.56, in: size),
                ])
                .fill(AppColors.accent.opacity(0.30))

                path([
                    point(0.14, 0.56, in: size),
                    point(0.50, 0.75, in: size),
                    point(0.50, 0.98, in: size),
                    point(0.14, 0.78, in: size),
                ])
                .fill(AppColors.accent.opacity(0.62))

                path([
                    point(0.50, 0.75, in: size),
                    point(0.86, 0.56, in: size),
                    point(0.86, 0.78, in: size),
                    point(0.50, 0.98, in: size),
                ])
                .fill(AppColors.accent)

                path([
                    point(0.50, 0.08, in: size),
                    point(0.83, 0.25, in: size),
                    point(0.50, 0.43, in: size),
                    point(0.17, 0.25, in: size),
                ])
                .fill(
                    LinearGradient(
                        colors: [AppColors.accent, AppColors.accent.opacity(0.62)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                path([
                    point(0.17, 0.25, in: size),
                    point(0.50, 0.43, in: size),
                    point(0.42, 0.53, in: size),
                    point(0.08, 0.35, in: size),
                ])
                .fill(AppColors.accent.opacity(0.42))

                path([
                    point(0.50, 0.43, in: size),
                    point(0.83, 0.25, in: size),
                    point(0.92, 0.35, in: size),
                    point(0.58, 0.53, in: size),
                ])
                .fill(AppColors.accent.opacity(0.74))
            }
        }
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * x, y: size.height * y)
    }

    private func path(_ points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            points.dropFirst().forEach { path.addLine(to: $0) }
            path.closeSubpath()
        }
    }
}

extension View {
    @ViewBuilder
    func adaptiveGlassSurface<S: InsettableShape>(
        tint: Color? = nil,
        isInteractive: Bool = false,
        in shape: S
    ) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(tint).interactive(isInteractive), in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(AppColors.hairline, lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    func adaptiveGlassButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    func adaptiveProminentGlassButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}
