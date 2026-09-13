# IPA Manager

IPA Manager is an iOS 17+ application foundation for importing, inspecting, and eventually re-signing IPA archives on device. This repository is currently an architecture scaffold: the Swift package graph, secure-import policy, native C ABIs, and CI build/release paths are established, while signing and direct device installation remain explicitly unsupported.

Swift owns SwiftUI, orchestration, storage, persistence, and Keychain integration. Rust owns Mach-O inspection and future device protocols. C++ is restricted to the future embedded signing-engine boundary. See `docs/architecture/overview.md` and `docs/security/threat-model.md` before adding a feature.

The Chromebook checkout is edit/Git only. Do not build locally. GitHub Actions on `ubuntu-24.04` and `xcode-27` performs all compilation, tests, dependency resolution, XCFramework generation, and unsigned IPA packaging. `ios/project.yml` is authoritative; never commit the generated Xcode project.

The canonical CI artifact is an unsigned `IPAManager.ipa` intended to be signed/installed by iLoader. It contains no provisioning profile or signing secret.
