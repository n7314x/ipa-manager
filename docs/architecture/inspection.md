# Inspection

Inspection starts only after the security-scoped source has been copied into app-controlled storage, hashed, made read-only, and persisted as an import. `IPALibraryService` then sends the managed `original.ipa` and managed workspace/cache locations to the `IPAInspection` package. Inspection failure changes the library item's status but does not silently delete the import.

The Phase 1B-A pipeline is: preflight every ZIP entry and aggregate resource limits; require exactly one immediate `Payload/*.app`; create a unique per-item workspace; extract with ZIPFoundation `0.9.20` while rechecking containment, CRC, type, and size; parse bounded property lists; select and copy at most one declared application icon; discover bundle components; record embedded provisioning-profile presence and decode it only where Apple's public CMS API is available; persist safe derived data; and remove the workspace.

The component graph identifies the main app, immediate `PlugIns/*.appex`, immediate `Frameworks/*.framework`, and nested `.app` bundles such as Watch apps. Extension and nested-app property lists provide names, identifiers, versions, builds, and executable-relative paths when available. No executable parsing occurs in this phase.

Root bundle metadata supports `CFBundleDisplayName`, `CFBundleName`, `CFBundleIdentifier`, `CFBundleShortVersionString`, `CFBundleVersion`, `CFBundleExecutable`, `MinimumOSVersion`, `UIDeviceFamily`, `CFBundlePackageType`, `DTPlatformName`, `DTPlatformVersion`, and `DTSDKName`. Icon resolution follows `CFBundleIcons`, `CFBundleIcons~ipad`, `CFBundleIconFiles`, and `CFBundleIconName`, validates the selected PNG's encoded and decoded size, and caches at most one managed icon.

When public CMS decoding is available, provisioning summaries include UUID, name, team identifiers/name, application-identifier prefixes, creation/expiration dates, provisioned-device count, enterprise-device scope, and a bounded typed entitlement dictionary. The iOS app records the embedded profile as present but decoding unavailable because Apple's CMS decoder is SPI-only there. It never stores the raw CMS payload or device identifier list.

Successful results are versioned and tied to the imported source SHA-256. The managed source is hashed before and after inspection so a changed source cannot receive cached results. A current, hash-matching result is reused across launches; legacy imports without one are inspected lazily. Persisted stale `inspecting` state is retryable after a terminated process. Failed attempts for the same immutable source remain failed instead of extracting again on every launch.

Phase 1B-B will pass executable bytes to the existing Rust/native architecture for Mach-O architectures, load commands, and embedded code-signature entitlements. Phase 1B-A neither links that native layer into the app target nor implements Swift Mach-O parsing. Inspection does not imply that an IPA is signable.
