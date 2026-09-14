import Foundation
import IPADomain

struct BundleComponentScanner {
    let infoPlistReader: any InfoPlistReading
    let policy: ArchiveSafetyPolicy

    init(
        infoPlistReader: (any InfoPlistReading)? = nil,
        policy: ArchiveSafetyPolicy = .default
    ) {
        self.infoPlistReader = infoPlistReader ?? InfoPlistReader(policy: policy)
        self.policy = policy
    }

    func scan(
        rootApplicationURL: URL,
        rootRelativePath: String,
        rootMetadata: AppBundleMetadata
    ) throws -> [BundleComponent] {
        let fileManager = FileManager()
        var children: [BundleComponent] = []

        let plugInsURL = rootApplicationURL.appending(path: "PlugIns", directoryHint: .isDirectory)
        children.append(contentsOf: try directBundles(
            in: plugInsURL,
            extension: "appex",
            kind: .extensionBundle,
            rootApplicationURL: rootApplicationURL,
            rootRelativePath: rootRelativePath,
            fileManager: fileManager
        ))

        let frameworksURL = rootApplicationURL.appending(path: "Frameworks", directoryHint: .isDirectory)
        if fileManager.fileExists(atPath: frameworksURL.path) {
            let frameworks = try safeDirectoryChildren(at: frameworksURL, fileManager: fileManager)
                .filter { $0.pathExtension.lowercased() == "framework" }
                .map { frameworkURL in
                    BundleComponent(
                        kind: .framework,
                        relativePath: relativeArchivePath(
                            for: frameworkURL,
                            rootApplicationURL: rootApplicationURL,
                            rootRelativePath: rootRelativePath
                        ),
                        displayName: frameworkURL.deletingPathExtension().lastPathComponent
                    )
                }
            children.append(contentsOf: frameworks)
        }

        children.append(contentsOf: try nestedApplications(
            in: rootApplicationURL,
            rootApplicationURL: rootApplicationURL,
            rootRelativePath: rootRelativePath,
            fileManager: fileManager
        ))

        children.sort {
            if $0.kind.rawValue == $1.kind.rawValue { return $0.relativePath < $1.relativePath }
            return $0.kind.rawValue < $1.kind.rawValue
        }
        let main = BundleComponent(
            kind: .application,
            relativePath: rootRelativePath,
            bundleIdentifier: rootMetadata.bundleIdentifier,
            displayName: rootMetadata.displayName,
            version: rootMetadata.shortVersion,
            buildVersion: rootMetadata.buildVersion,
            executableRelativePath: executablePath(rootMetadata.executableName, bundlePath: rootRelativePath),
            childIDs: children.map(\.id)
        )
        return [main] + children
    }

    private func directBundles(
        in directory: URL,
        extension pathExtension: String,
        kind: BundleComponent.Kind,
        rootApplicationURL: URL,
        rootRelativePath: String,
        fileManager: FileManager
    ) throws -> [BundleComponent] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        return try safeDirectoryChildren(at: directory, fileManager: fileManager)
            .filter { $0.pathExtension.lowercased() == pathExtension }
            .map { bundleURL in
                let bundlePath = relativeArchivePath(
                    for: bundleURL,
                    rootApplicationURL: rootApplicationURL,
                    rootRelativePath: rootRelativePath
                )
                let metadata = try? infoPlistReader.readInfoPlist(
                    in: bundleURL,
                    fallbackName: bundleURL.deletingPathExtension().lastPathComponent,
                    maximumBytes: policy.maximumInfoPlistBytes
                )
                return BundleComponent(
                    kind: kind,
                    relativePath: bundlePath,
                    bundleIdentifier: metadata?.bundleIdentifier,
                    displayName: metadata?.displayName,
                    version: metadata?.shortVersion,
                    buildVersion: metadata?.buildVersion,
                    executableRelativePath: executablePath(metadata?.executableName, bundlePath: bundlePath)
                )
            }
    }

    private func safeDirectoryChildren(at url: URL, fileManager: FileManager) throws -> [URL] {
        let children = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        )
        return try children.filter { child in
            let values = try child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard values.isSymbolicLink != true else {
                throw IPAError.unsafeArchive("the extracted bundle contains a symbolic link")
            }
            return values.isDirectory == true
        }
    }

    private func nestedApplications(
        in directory: URL,
        rootApplicationURL: URL,
        rootRelativePath: String,
        fileManager: FileManager
    ) throws -> [BundleComponent] {
        var applications: [BundleComponent] = []
        for child in try safeDirectoryChildren(at: directory, fileManager: fileManager) {
            let pathExtension = child.pathExtension.lowercased()
            if pathExtension == "app" {
                let nestedRelativePath = relativeArchivePath(
                    for: child,
                    rootApplicationURL: rootApplicationURL,
                    rootRelativePath: rootRelativePath
                )
                let metadata = try? infoPlistReader.readInfoPlist(
                    in: child,
                    fallbackName: child.deletingPathExtension().lastPathComponent,
                    maximumBytes: policy.maximumInfoPlistBytes
                )
                applications.append(BundleComponent(
                    kind: .nestedApplication,
                    relativePath: nestedRelativePath,
                    bundleIdentifier: metadata?.bundleIdentifier,
                    displayName: metadata?.displayName,
                    version: metadata?.shortVersion,
                    buildVersion: metadata?.buildVersion,
                    executableRelativePath: executablePath(
                        metadata?.executableName,
                        bundlePath: nestedRelativePath
                    )
                ))
            } else if !["appex", "bundle", "framework", "xcframework"].contains(pathExtension) {
                applications.append(contentsOf: try nestedApplications(
                    in: child,
                    rootApplicationURL: rootApplicationURL,
                    rootRelativePath: rootRelativePath,
                    fileManager: fileManager
                ))
            }
        }
        return applications
    }

    private func relativeArchivePath(
        for url: URL,
        rootApplicationURL: URL,
        rootRelativePath: String
    ) -> String {
        let rootComponents = rootApplicationURL.standardizedFileURL.pathComponents
        let childComponents = url.standardizedFileURL.pathComponents
        let suffix = childComponents.dropFirst(rootComponents.count).joined(separator: "/")
        return suffix.isEmpty ? rootRelativePath : "\(rootRelativePath)/\(suffix)"
    }

    private func executablePath(_ executable: String?, bundlePath: String) -> String? {
        guard let executable, !executable.isEmpty,
              !executable.contains("/"), !executable.contains("\\")
        else { return nil }
        return "\(bundlePath)/\(executable)"
    }
}
