# IPA Manager

IPA Manager is an iOS 17+ application foundation for importing, inspecting, and eventually re-signing IPA archives on device.

- **Phase 1A — complete and device-verified:** persistent managed IPA library, security-scoped file import, basic ZIP validation, SHA-256 deduplication, and removal.
- **Phase 1B-A — implemented:** hostile-archive preflight, isolated extraction, application plist/icon/component inspection, embedded provisioning-profile presence with a public-API decoding boundary, persisted inspection state, and metadata UI.
- **Phase 1B-B — next:** native Rust Mach-O, architecture, load-command, and embedded code-signature entitlement inspection.

Signing, re-signing, Apple account access, and direct device installation remain explicitly unsupported.

Swift owns SwiftUI, orchestration, secure ZIP extraction, bundle metadata, storage, persistence, and Keychain integration. Rust remains the owner of Mach-O inspection and future device protocols; Phase 1B-A does not introduce a competing Swift Mach-O parser. C++ is restricted to the future embedded signing-engine boundary. See `docs/architecture/overview.md`, `docs/architecture/inspection.md`, and `docs/security/ipa-validation.md` before adding a feature.

The Chromebook checkout is edit/Git only. Do not build locally. GitHub Actions on `ubuntu-24.04` and `xcode-27` performs all compilation, tests, dependency resolution, XCFramework generation, and unsigned IPA packaging. `ios/project.yml` is authoritative; never commit the generated Xcode project.

The canonical CI artifact is an unsigned `IPAManager.ipa` intended to be signed/installed by iLoader. It contains no provisioning profile or signing secret.
