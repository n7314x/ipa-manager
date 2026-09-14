import Foundation
import IPADomain
import XCTest
import ZIPFoundation
@testable import IPAInspection

@MainActor
final class IPAInspectionTests: XCTestCase {
    func testValidMinimalIPAIsPreflightedExtractedAndInspected() async throws {
        try await withTemporaryDirectory { directory in
            let ipaURL = directory.appending(path: "Minimal.ipa")
            try makeArchive(
                at: ipaURL,
                entries: [
                    "Payload/Minimal.app/Info.plist": try plistData([
                        "CFBundleDisplayName": "Minimal",
                        "CFBundleIdentifier": "example.minimal",
                        "CFBundleShortVersionString": "1.2.3",
                        "CFBundleVersion": "45",
                        "CFBundleExecutable": "Minimal",
                    ]),
                    "Payload/Minimal.app/embedded.mobileprovision": Data("invalid-cms-fixture".utf8),
                ]
            )
            let work = directory.appending(path: "work", directoryHint: .isDirectory)
            let metadata = directory.appending(path: "metadata", directoryHint: .isDirectory)
            let identifier = UUID()

            let result = try await IPAInspectionService(
                capacityProvider: FixedInspectionStorageCapacityProvider(availableCapacity: .max),
                dateProvider: { Date(timeIntervalSince1970: 1_700_000_000) }
            ).inspect(IPAInspectionRequest(
                importedIPAID: identifier,
                sourceSHA256: String(repeating: "a", count: 64),
                originalIPAURL: ipaURL,
                workDirectory: work,
                metadataDirectory: metadata,
                iconCacheRelativePath: "Library/id/metadata/app-icon.png"
            ))

            XCTAssertEqual(result.importedIPAID, identifier)
            XCTAssertEqual(result.rootApplication.displayName, "Minimal")
            XCTAssertEqual(result.rootApplication.bundleIdentifier, "example.minimal")
            XCTAssertEqual(result.rootApplication.relativePath, "Payload/Minimal.app")
            XCTAssertEqual(result.components.map(\.kind), [.application])
            XCTAssertEqual(result.provisioningProfile?.decodeStatus, .unavailable)
            XCTAssertEqual(
                result.provisioningProfile?.relativePath,
                "Payload/Minimal.app/embedded.mobileprovision"
            )
            XCTAssertEqual(result.existingEntitlements, .unavailable)
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: work.path), [])
        }
    }

    func testPayloadStructureRequiresExactlyOneImmediateApplication() throws {
        let validator = ArchivePreflightValidator()
        XCTAssertThrowsError(try validator.rootApplicationPath(in: ["Other/App.app/Info.plist"])) { error in
            XCTAssertEqual(error as? IPAError, .invalidPayloadStructure)
        }
        XCTAssertThrowsError(try validator.rootApplicationPath(in: ["Payload/readme.txt"])) { error in
            XCTAssertEqual(error as? IPAError, .missingApplicationBundle)
        }
        XCTAssertThrowsError(try validator.rootApplicationPath(in: [
            "Payload/One.app/Info.plist", "Payload/Two.app/Info.plist",
        ])) { error in
            XCTAssertEqual(error as? IPAError, .multipleRootApplications)
        }
        XCTAssertEqual(
            try validator.rootApplicationPath(in: [
                "Payload/Main.app/Info.plist",
                "Payload/Main.app/Watch/Nested.app/Info.plist",
            ]),
            "Payload/Main.app"
        )
    }

    func testPathTraversalAndAbsolutePathsAreRejected() {
        for path in [
            "../evil",
            "Payload/../evil",
            "Payload/App.app/../../evil",
            "/etc/passwd",
            "/private/var/mobile/file",
            "C:\\something",
            "C:/something",
        ] {
            XCTAssertThrowsError(try ArchiveSafetyPolicy.default.normalizedPath(path), path)
        }
    }

    func testDuplicateNormalizedPathsAreRejected() {
        let decomposed = "Payload/Cafe\u{301}.app/Info.plist"
        let composed = "Payload/Café.app/Info.plist"
        XCTAssertThrowsError(try ArchiveSafetyPolicy.default.validate([
            descriptor("Payload/Test.app/Info.plist"),
            descriptor("Payload/Test.app/Info.plist"),
        ])) { error in
            XCTAssertEqual(error as? IPAError, .duplicateArchiveEntry)
        }
        XCTAssertThrowsError(try ArchiveSafetyPolicy.default.validate([
            descriptor(decomposed), descriptor(composed),
        ])) { error in
            XCTAssertEqual(error as? IPAError, .duplicateArchiveEntry)
        }
        XCTAssertThrowsError(try ArchiveSafetyPolicy.default.validate([
            descriptor("Payload/App.app/Icon.png"),
            descriptor("Payload/App.app/icon.png"),
        ])) { error in
            XCTAssertEqual(error as? IPAError, .duplicateArchiveEntry)
        }
        XCTAssertThrowsError(try ArchiveSafetyPolicy.default.validate([
            descriptor("Payload/App.app/Resources"),
            descriptor("Payload/App.app/Resources/", uncompressed: 0),
        ])) { error in
            XCTAssertEqual(error as? IPAError, .duplicateArchiveEntry)
        }
    }

    func testMalformedCentralDirectoryEntryCountFailsCleanly() throws {
        try withTemporaryDirectory { directory in
            let ipaURL = directory.appending(path: "Malformed.ipa")
            try makeArchive(
                at: ipaURL,
                entries: ["Payload/App.app/Info.plist": try plistData([:])]
            )
            var data = try Data(contentsOf: ipaURL)
            guard let endIndex = endOfCentralDirectoryIndex(in: data) else {
                return XCTFail("Synthetic archive did not contain an end-of-central-directory record")
            }
            data[endIndex + 8] = 2
            data[endIndex + 9] = 0
            data[endIndex + 10] = 2
            data[endIndex + 11] = 0
            try data.write(to: ipaURL)

            XCTAssertThrowsError(try ArchivePreflightValidator().preflight(archiveAt: ipaURL)) { error in
                XCTAssertEqual(error as? IPAError, .inspectionFailure)
            }
        }
    }

    func testSymbolicLinksAreRejected() {
        XCTAssertThrowsError(try ArchiveSafetyPolicy.default.validate([
            ArchiveEntryDescriptor(
                path: "Payload/App.app/link",
                compressedSize: 4,
                uncompressedSize: 4,
                kind: .symbolicLink
            ),
        ]))
    }

    func testFileDirectoryCollisionsAreRejectedBeforeExtraction() {
        XCTAssertThrowsError(try ArchiveSafetyPolicy.default.validate([
            descriptor("Payload/App.app/Resources"),
            descriptor("Payload/App.app/Resources/icon.png"),
        ])) { error in
            guard let ipaError = error as? IPAError, case .unsafeArchive = ipaError else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testEntryTotalCountAndCompressionLimitsAreRejected() {
        XCTAssertThrowsError(try ArchiveSafetyPolicy(
            maximumEntryUncompressedBytes: 10
        ).validate([
            descriptor("Payload/App.app/large", compressed: 1, uncompressed: 11),
        ])) { error in
            XCTAssertEqual(error as? IPAError, .archiveEntryTooLarge(maximumBytes: 10))
        }

        XCTAssertThrowsError(try ArchiveSafetyPolicy(
            maximumTotalUncompressedBytes: 10,
            maximumEntryUncompressedBytes: 10
        ).validate([
            descriptor("Payload/App.app/one", compressed: 6, uncompressed: 6),
            descriptor("Payload/App.app/two", compressed: 5, uncompressed: 5),
        ])) { error in
            XCTAssertEqual(error as? IPAError, .archiveTooLarge(maximumBytes: 10))
        }

        XCTAssertThrowsError(try ArchiveSafetyPolicy(maximumEntryCount: 1).validate([
            descriptor("Payload/App.app/one"), descriptor("Payload/App.app/two"),
        ])) { error in
            XCTAssertEqual(error as? IPAError, .tooManyArchiveEntries(maximumCount: 1))
        }

        XCTAssertThrowsError(try ArchiveSafetyPolicy(
            maximumEntryUncompressedBytes: 1_000,
            maximumCompressionRatio: 200
        ).validate([
            descriptor("Payload/App.app/bomb", compressed: 1, uncompressed: 201),
        ])) { error in
            XCTAssertEqual(error as? IPAError, .suspiciousCompressionRatio(maximumRatio: 200))
        }

        XCTAssertThrowsError(try ArchiveSafetyPolicy.default.validate([
            descriptor("Payload/App.app/impossible", compressed: 0, uncompressed: 1),
        ]))
    }

    func testPolicyAcceptsExactResourceBoundaries() throws {
        let path = "a/b"
        let policy = ArchiveSafetyPolicy(
            maximumEntryCount: 1,
            maximumTotalUncompressedBytes: 10,
            maximumEntryUncompressedBytes: 10,
            maximumCompressionRatio: 10,
            maximumPathBytes: path.utf8.count,
            maximumNestingDepth: 2
        )
        XCTAssertEqual(
            try policy.validate([
                descriptor(path, compressed: 1, uncompressed: 10),
            ]),
            [path]
        )
    }

    func testEnoughStorageCapacityAllowsExtractionToProceed() throws {
        let capacityGuard = InspectionStorageCapacityGuard(
            policy: ArchiveSafetyPolicy(inspectionStorageSafetyReserveBytes: 100),
            capacityProvider: FixedInspectionStorageCapacityProvider(availableCapacity: 501)
        )

        XCTAssertNoThrow(try capacityGuard.validate(
            declaredUncompressedBytes: 400,
            workspaceURL: URL(fileURLWithPath: "/ignored-test-workspace")
        ))
    }

    func testInsufficientStorageCapacityIsRejectedBeforeExtraction() async throws {
        try await withTemporaryDirectory { directory in
            let malformedPlist = Data("broken".utf8)
            let ipaURL = directory.appending(path: "StorageGuard.ipa")
            try makeArchive(
                at: ipaURL,
                entries: ["Payload/StorageGuard.app/Info.plist": malformedPlist]
            )
            let work = directory.appending(path: "work", directoryHint: .isDirectory)
            let policy = ArchiveSafetyPolicy(inspectionStorageSafetyReserveBytes: 100)

            do {
                _ = try await IPAInspectionService(
                    policy: policy,
                    capacityProvider: FixedInspectionStorageCapacityProvider(availableCapacity: 105)
                ).inspect(IPAInspectionRequest(
                    importedIPAID: UUID(),
                    sourceSHA256: "hash",
                    originalIPAURL: ipaURL,
                    workDirectory: work,
                    metadataDirectory: directory.appending(path: "metadata"),
                    iconCacheRelativePath: "Library/id/metadata/app-icon.png"
                ))
                XCTFail("Expected storage capacity failure")
            } catch {
                XCTAssertEqual(
                    error as? IPAError,
                    .insufficientStorage(requiredBytes: UInt64(malformedPlist.count) + 100)
                )
            }

            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: work.path), [])
        }
    }

    func testStorageCapacityAcceptsExactRequiredBoundary() throws {
        let capacityGuard = InspectionStorageCapacityGuard(
            policy: ArchiveSafetyPolicy(inspectionStorageSafetyReserveBytes: 100),
            capacityProvider: FixedInspectionStorageCapacityProvider(availableCapacity: 500)
        )

        XCTAssertNoThrow(try capacityGuard.validate(
            declaredUncompressedBytes: 400,
            workspaceURL: URL(fileURLWithPath: "/ignored-test-workspace")
        ))
    }

    func testRequiredStorageCapacityAdditionRejectsOverflow() {
        let capacityGuard = InspectionStorageCapacityGuard(
            policy: ArchiveSafetyPolicy(inspectionStorageSafetyReserveBytes: .max),
            capacityProvider: FixedInspectionStorageCapacityProvider(availableCapacity: .max)
        )

        XCTAssertThrowsError(try capacityGuard.requiredCapacity(for: 1)) { error in
            XCTAssertEqual(error as? IPAError, .insufficientStorage(requiredBytes: .max))
        }
    }

    func testUnavailableStorageCapacityFailsSafely() {
        let capacityGuard = InspectionStorageCapacityGuard(
            policy: ArchiveSafetyPolicy(inspectionStorageSafetyReserveBytes: 100),
            capacityProvider: UnavailableInspectionStorageCapacityProvider()
        )

        XCTAssertThrowsError(try capacityGuard.validate(
            declaredUncompressedBytes: 400,
            workspaceURL: URL(fileURLWithPath: "/ignored-test-workspace")
        )) { error in
            XCTAssertEqual(error as? IPAError, .insufficientStorage(requiredBytes: 500))
        }
    }

    func testInsufficientStorageMapsToResourceLimitFailure() {
        XCTAssertEqual(
            InspectionFailureReason(
                inspectionError: IPAError.insufficientStorage(requiredBytes: 1_000)
            ),
            .resourceLimit
        )
    }

    func testPathLengthNestingAndContainmentBoundaries() throws {
        let policy = ArchiveSafetyPolicy(maximumPathBytes: 8, maximumNestingDepth: 2)
        XCTAssertThrowsError(try policy.normalizedPath("Payload/TooLong.app"))
        XCTAssertThrowsError(try policy.normalizedPath("a/b/c"))

        let root = URL(fileURLWithPath: "/tmp/work", isDirectory: true)
        XCTAssertTrue(ArchiveSafetyPolicy.default.contains(
            URL(fileURLWithPath: "/tmp/work/Payload/App.app"),
            inside: root
        ))
        XCTAssertFalse(ArchiveSafetyPolicy.default.contains(
            URL(fileURLWithPath: "/tmp/work-evil/file"),
            inside: root
        ))
    }

    func testMissingAndMalformedInfoPlistFailCleanly() throws {
        try withTemporaryDirectory { directory in
            let appURL = directory.appending(path: "Missing.app", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
            XCTAssertThrowsError(try AppBundleInspector().inspect(
                appAt: appURL,
                relativePath: "Payload/Missing.app"
            )) { error in
                XCTAssertEqual(error as? IPAError, .missingInfoPlist)
            }

            try Data("not a plist".utf8).write(to: appURL.appending(path: "Info.plist"))
            XCTAssertThrowsError(try AppBundleInspector().inspect(
                appAt: appURL,
                relativePath: "Payload/Missing.app"
            )) { error in
                XCTAssertEqual(error as? IPAError, .malformedInfoPlist)
            }
        }
    }

    func testXMLAndBinaryInfoPlistsAreSupported() throws {
        let dictionary: [String: Any] = [
            "CFBundleDisplayName": "Fixture App",
            "CFBundleName": "Fixture",
            "CFBundleIdentifier": "example.fixture",
            "CFBundleShortVersionString": "3.8.0",
            "CFBundleVersion": "900",
            "CFBundleExecutable": "Fixture",
            "MinimumOSVersion": "17.0",
            "UIDeviceFamily": [1, 2],
            "CFBundlePackageType": "APPL",
            "DTPlatformName": "iphoneos",
            "DTPlatformVersion": "26.0",
            "DTSDKName": "iphoneos26.0",
            "CFBundleIconFiles": ["LegacyIcon"],
            "CFBundleIconName": "RootAssetIcon",
            "CFBundleIcons": [
                "CFBundlePrimaryIcon": [
                    "CFBundleIconFiles": ["AppIcon60x60"],
                    "CFBundleIconName": "AppIcon",
                ],
            ],
            "CFBundleIcons~ipad": [
                "CFBundlePrimaryIcon": [
                    "CFBundleIconFiles": ["AppIcon76x76"],
                ],
            ],
        ]
        for format in [PropertyListSerialization.PropertyListFormat.xml, .binary] {
            let parsed = try InfoPlistReader().parse(
                data: try plistData(dictionary, format: format),
                fallbackName: "Fallback"
            )
            XCTAssertEqual(parsed.displayName, "Fixture App")
            XCTAssertEqual(parsed.bundleName, "Fixture")
            XCTAssertEqual(parsed.bundleIdentifier, "example.fixture")
            XCTAssertEqual(parsed.shortVersion, "3.8.0")
            XCTAssertEqual(parsed.buildVersion, "900")
            XCTAssertEqual(parsed.executableName, "Fixture")
            XCTAssertEqual(parsed.minimumOSVersion, "17.0")
            XCTAssertEqual(parsed.deviceFamilies, [1, 2])
            XCTAssertEqual(parsed.packageType, "APPL")
            XCTAssertEqual(parsed.platformName, "iphoneos")
            XCTAssertEqual(parsed.platformVersion, "26.0")
            XCTAssertEqual(parsed.sdkName, "iphoneos26.0")
            XCTAssertTrue(parsed.iconNames.contains("LegacyIcon"))
            XCTAssertTrue(parsed.iconNames.contains("RootAssetIcon"))
            XCTAssertTrue(parsed.iconNames.contains("AppIcon60x60"))
            XCTAssertTrue(parsed.iconNames.contains("AppIcon"))
            XCTAssertTrue(parsed.iconNames.contains("AppIcon76x76"))
        }
    }

    func testDisplayNameFallsBackFromBundleNameToFilenameStem() throws {
        let reader = InfoPlistReader()
        XCTAssertEqual(
            try reader.parse(
                data: try plistData(["CFBundleName": "Bundle Name"]),
                fallbackName: "Filename"
            ).displayName,
            "Bundle Name"
        )
        XCTAssertEqual(
            try reader.parse(data: try plistData([:]), fallbackName: "Filename").displayName,
            "Filename"
        )
    }

    func testAttackerControlledPlistCollectionsAndStringsAreBounded() throws {
        let reader = InfoPlistReader(policy: ArchiveSafetyPolicy(
            maximumMetadataStringBytes: 4,
            maximumIconDeclarationCount: 1,
            maximumDeviceFamilyCount: 1
        ))
        let parsed = try reader.parse(
            data: try plistData([
                "CFBundleDisplayName": "Far Too Long",
                "CFBundleName": "App",
                "CFBundleIdentifier": "example.oversized",
                "UIDeviceFamily": [1, 2],
                "CFBundleIconFiles": ["One", "Two"],
            ]),
            fallbackName: "File"
        )

        XCTAssertEqual(parsed.displayName, "App")
        XCTAssertNil(parsed.bundleIdentifier)
        XCTAssertTrue(parsed.deviceFamilies.isEmpty)
        XCTAssertEqual(parsed.iconNames, ["One"])
    }

    func testExtensionFrameworkAndNestedApplicationDiscovery() throws {
        try withTemporaryDirectory { directory in
            let appURL = directory.appending(path: "Main.app", directoryHint: .isDirectory)
            let extensionURL = appURL.appending(path: "PlugIns/Widget.appex", directoryHint: .isDirectory)
            let frameworkURL = appURL.appending(path: "Frameworks/Example.framework", directoryHint: .isDirectory)
            let watchURL = appURL.appending(path: "Watch/WatchApp.app", directoryHint: .isDirectory)
            for url in [extensionURL, frameworkURL, watchURL] {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }
            try plistData([
                "CFBundleDisplayName": "Widget",
                "CFBundleIdentifier": "example.main.widget",
                "CFBundleShortVersionString": "1.0",
                "CFBundleVersion": "2",
            ]).write(to: extensionURL.appending(path: "Info.plist"))
            try plistData([
                "CFBundleDisplayName": "Watch App",
                "CFBundleIdentifier": "example.main.watch",
            ]).write(to: watchURL.appending(path: "Info.plist"))

            let root = AppBundleMetadata(
                displayName: "Main",
                bundleIdentifier: "example.main",
                relativePath: "Payload/Main.app"
            )
            let components = try BundleComponentScanner().scan(
                rootApplicationURL: appURL,
                rootRelativePath: "Payload/Main.app",
                rootMetadata: root
            )

            XCTAssertEqual(components.filter { $0.kind == .application }.count, 1)
            XCTAssertEqual(components.filter { $0.kind == .extensionBundle }.count, 1)
            XCTAssertEqual(components.filter { $0.kind == .framework }.count, 1)
            XCTAssertEqual(components.filter { $0.kind == .nestedApplication }.count, 1)
            XCTAssertTrue(components.contains {
                $0.kind == .extensionBundle && $0.bundleIdentifier == "example.main.widget"
            })
            XCTAssertTrue(components.contains {
                $0.kind == .nestedApplication && $0.relativePath == "Payload/Main.app/Watch/WatchApp.app"
            })
        }
    }

    func testDeclaredHighestQualityIconIsCachedOnce() throws {
        try withTemporaryDirectory { directory in
            let appURL = directory.appending(path: "Icon.app", directoryHint: .isDirectory)
            let metadataURL = directory.appending(path: "metadata", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
            let png = try tinyPNGData()
            try png.write(to: appURL.appending(path: "AppIcon60x60@2x.png"))
            try (png + Data([0])).write(to: appURL.appending(path: "AppIcon60x60@3x.png"))

            let icon = try AppIconResolver().resolveAndCache(
                appAt: appURL,
                declaredNames: ["AppIcon60x60"],
                cacheURL: metadataURL.appending(path: "app-icon.png"),
                cacheRelativePath: "Library/id/metadata/app-icon.png",
                fileManager: FileManager.default
            )

            XCTAssertEqual(icon?.relativePath, "Library/id/metadata/app-icon.png")
            XCTAssertEqual(icon?.byteSize, Int64(png.count + 1))
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: metadataURL.path), ["app-icon.png"])
        }
    }

    func testIconDecodedDimensionsAreBounded() throws {
        try withTemporaryDirectory { directory in
            let appURL = directory.appending(path: "Icon.app", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
            try tinyPNGData().write(to: appURL.appending(path: "AppIcon.png"))

            let icon = try AppIconResolver(policy: ArchiveSafetyPolicy(
                maximumIconPixelDimension: 0,
                maximumIconPixelCount: 0
            )).resolveAndCache(
                appAt: appURL,
                declaredNames: ["AppIcon"],
                cacheURL: directory.appending(path: "metadata/app-icon.png"),
                cacheRelativePath: "Library/id/metadata/app-icon.png",
                fileManager: FileManager.default
            )

            XCTAssertNil(icon)
            XCTAssertFalse(FileManager.default.fileExists(
                atPath: directory.appending(path: "metadata/app-icon.png").path
            ))
        }
    }

    func testProvisioningMetadataParserKeepsCountsNotDeviceIdentifiers() throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let expires = Date(timeIntervalSince1970: 1_800_000_000)
        let data = try plistData([
            "UUID": "PROFILE-UUID",
            "Name": "Development Profile",
            "TeamIdentifier": ["TEAMID"],
            "TeamName": "Example Team",
            "ApplicationIdentifierPrefix": ["TEAMID"],
            "CreationDate": created,
            "ExpirationDate": expires,
            "ProvisionedDevices": ["UDID-ONE", "UDID-TWO"],
            "ProvisionsAllDevices": false,
            "Entitlements": [
                "application-identifier": "TEAMID.example.app",
                "get-task-allow": true,
            ],
        ])

        let profile = try ProvisioningProfileReader().parseDecodedPropertyList(
            data,
            relativePath: "Payload/App.app/embedded.mobileprovision",
            maximumValueCount: 100
        )

        XCTAssertEqual(profile.decodeStatus, .decoded)
        XCTAssertEqual(profile.profileUUID, "PROFILE-UUID")
        XCTAssertEqual(profile.name, "Development Profile")
        XCTAssertEqual(profile.teamIdentifiers, ["TEAMID"])
        XCTAssertEqual(profile.teamName, "Example Team")
        XCTAssertEqual(profile.applicationIdentifierPrefixes, ["TEAMID"])
        XCTAssertEqual(profile.creationDate, created)
        XCTAssertEqual(profile.expirationDate, expires)
        XCTAssertEqual(profile.provisionedDevicesCount, 2)
        XCTAssertEqual(profile.provisionsAllDevices, false)
        XCTAssertEqual(profile.entitlements?["get-task-allow"], .boolean(true))
    }

    func testWorkspaceIsRemovedWhenInspectionFails() async throws {
        try await withTemporaryDirectory { directory in
            let ipaURL = directory.appending(path: "Broken.ipa")
            try makeArchive(
                at: ipaURL,
                entries: ["Payload/Broken.app/Info.plist": Data("broken".utf8)]
            )
            let work = directory.appending(path: "work", directoryHint: .isDirectory)
            do {
                _ = try await IPAInspectionService(
                    capacityProvider: FixedInspectionStorageCapacityProvider(availableCapacity: .max)
                ).inspect(IPAInspectionRequest(
                    importedIPAID: UUID(),
                    sourceSHA256: "hash",
                    originalIPAURL: ipaURL,
                    workDirectory: work,
                    metadataDirectory: directory.appending(path: "metadata"),
                    iconCacheRelativePath: "Library/id/metadata/app-icon.png"
                ))
                XCTFail("Expected malformed plist failure")
            } catch {
                XCTAssertEqual(error as? IPAError, .malformedInfoPlist)
            }
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: work.path), [])
        }
    }

    func testBundleGraphSignsParentLast() throws {
        let child = BundleComponent(kind: .extensionBundle, relativePath: "Payload/App.app/PlugIns/Widget.appex")
        let root = BundleComponent(kind: .application, relativePath: "Payload/App.app", childIDs: [child.id])
        XCTAssertEqual(
            try BundleGraphBuilder().signingOrder(components: [root, child], rootID: root.id),
            [child.id, root.id]
        )
    }

    private func descriptor(
        _ path: String,
        compressed: UInt64 = 1,
        uncompressed: UInt64 = 1
    ) -> ArchiveEntryDescriptor {
        ArchiveEntryDescriptor(path: path, compressedSize: compressed, uncompressedSize: uncompressed)
    }

    private func plistData(
        _ dictionary: [String: Any],
        format: PropertyListSerialization.PropertyListFormat = .xml
    ) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: dictionary, format: format, options: 0)
    }

    private func makeArchive(at url: URL, entries: [String: Data]) throws {
        let sourceDirectory = url.deletingLastPathComponent().appending(
            path: "archive-source-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: sourceDirectory) }
        let archive = try Archive(url: url, accessMode: .create)
        for (index, entry) in entries.sorted(by: { $0.key < $1.key }).enumerated() {
            let source = sourceDirectory.appending(path: "entry-\(index)")
            try entry.value.write(to: source)
            try archive.addEntry(with: entry.key, fileURL: source, compressionMethod: .deflate)
        }
    }

    private func tinyPNGData() throws -> Data {
        guard let data = Data(
            base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
        ) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return data
    }

    private func endOfCentralDirectoryIndex(in data: Data) -> Int? {
        guard data.count >= 22 else { return nil }
        for index in stride(from: data.count - 22, through: 0, by: -1) {
            guard data[index] == 0x50,
                  data[index + 1] == 0x4B,
                  data[index + 2] == 0x05,
                  data[index + 3] == 0x06
            else { continue }
            return index
        }
        return nil
    }

    private func withTemporaryDirectory<T>(_ body: (URL) throws -> T) throws -> T {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "IPAInspectionTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        return try body(directory)
    }

    private func withTemporaryDirectory<T>(_ body: (URL) async throws -> T) async throws -> T {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "IPAInspectionTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        return try await body(directory)
    }
}

private struct FixedInspectionStorageCapacityProvider: InspectionStorageCapacityProviding {
    let availableCapacity: UInt64

    func availableCapacity(forVolumeContaining url: URL) throws -> UInt64 {
        availableCapacity
    }
}

private struct UnavailableInspectionStorageCapacityProvider: InspectionStorageCapacityProviding {
    func availableCapacity(forVolumeContaining url: URL) throws -> UInt64 {
        throw CocoaError(.fileReadUnknown)
    }
}
