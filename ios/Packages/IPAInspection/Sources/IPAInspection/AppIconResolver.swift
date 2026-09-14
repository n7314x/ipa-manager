import Foundation
import ImageIO
import IPADomain

struct AppIconResolver {
    let policy: ArchiveSafetyPolicy

    init(policy: ArchiveSafetyPolicy = .default) {
        self.policy = policy
    }

    func resolveAndCache(
        appAt appURL: URL,
        declaredNames: [String],
        cacheURL: URL,
        cacheRelativePath: String,
        fileManager: FileManager
    ) throws -> AppIconMetadata? {
        let declarations = declaredNames.compactMap(safeStem)
        guard !declarations.isEmpty else { return nil }

        let children = try fileManager.contentsOfDirectory(
            at: appURL,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        )
        let candidates = children.compactMap { url -> IconCandidate? in
            guard url.pathExtension.lowercased() == "png",
                  let stem = safeStem(url.lastPathComponent),
                  let match = bestMatch(for: stem, declarations: declarations)
            else { return nil }

            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey])
            guard values?.isRegularFile == true,
                  values?.isSymbolicLink != true,
                  let fileSize = values?.fileSize,
                  fileSize > 0,
                  UInt64(fileSize) <= policy.maximumIconBytes,
                  hasPNGSignature(at: url)
            else { return nil }

            guard let dimensions = imageDimensions(at: url),
                  dimensions.width <= policy.maximumIconPixelDimension,
                  dimensions.height <= policy.maximumIconPixelDimension
            else { return nil }
            let (pixelCount, pixelCountOverflow) = UInt64(dimensions.width).multipliedReportingOverflow(
                by: UInt64(dimensions.height)
            )
            guard !pixelCountOverflow, pixelCount <= policy.maximumIconPixelCount else { return nil }
            return IconCandidate(
                url: url,
                exactNameMatch: match,
                pixelWidth: dimensions.width,
                pixelHeight: dimensions.height,
                scale: filenameScale(url.lastPathComponent),
                byteSize: Int64(fileSize)
            )
        }

        guard let selected = candidates.max(by: { $0.isLowerQuality(than: $1) }) else { return nil }
        try fileManager.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let temporaryCacheURL = cacheURL.deletingLastPathComponent().appending(
            path: "app-icon-\(UUID().uuidString).png"
        )
        do {
            try fileManager.copyItem(at: selected.url, to: temporaryCacheURL)
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: temporaryCacheURL.path)
            if fileManager.fileExists(atPath: cacheURL.path) {
                _ = try fileManager.replaceItemAt(cacheURL, withItemAt: temporaryCacheURL)
            } else {
                try fileManager.moveItem(at: temporaryCacheURL, to: cacheURL)
            }
        } catch {
            try? fileManager.removeItem(at: temporaryCacheURL)
            throw error
        }

        return AppIconMetadata(
            relativePath: cacheRelativePath,
            pixelWidth: selected.pixelWidth,
            pixelHeight: selected.pixelHeight,
            byteSize: selected.byteSize
        )
    }

    private func safeStem(_ path: String) -> String? {
        guard !path.contains("/"), !path.contains("\\") else { return nil }
        var stem = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        for suffix in ["~ipad", "~iphone"] where stem.lowercased().hasSuffix(suffix) {
            stem.removeLast(suffix.count)
        }
        for suffix in ["@3x", "@2x", "@1x"] where stem.lowercased().hasSuffix(suffix) {
            stem.removeLast(suffix.count)
        }
        return stem.isEmpty ? nil : stem.lowercased()
    }

    private func bestMatch(for candidate: String, declarations: [String]) -> Bool? {
        if declarations.contains(candidate) { return true }
        return declarations.contains(where: { candidate.hasPrefix($0) }) ? false : nil
    }

    private func hasPNGSignature(at url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        guard let signature = try? handle.read(upToCount: 8) else { return false }
        return signature == Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    }

    private func imageDimensions(at url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
              width > 0,
              height > 0
        else { return nil }
        return (width, height)
    }

    private func filenameScale(_ filename: String) -> Int {
        if filename.localizedCaseInsensitiveContains("@3x") { return 3 }
        if filename.localizedCaseInsensitiveContains("@2x") { return 2 }
        return 1
    }
}

private struct IconCandidate {
    let url: URL
    let exactNameMatch: Bool
    let pixelWidth: Int
    let pixelHeight: Int
    let scale: Int
    let byteSize: Int64

    func isLowerQuality(than other: IconCandidate) -> Bool {
        let pixels = Int64(pixelWidth) * Int64(pixelHeight)
        let otherPixels = Int64(other.pixelWidth) * Int64(other.pixelHeight)
        if pixels != otherPixels { return pixels < otherPixels }
        if scale != other.scale { return scale < other.scale }
        if exactNameMatch != other.exactNameMatch { return !exactNameMatch }
        return byteSize < other.byteSize
    }
}
