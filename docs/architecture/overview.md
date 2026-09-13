# Architecture overview

IPA Manager is split by responsibility rather than by feature screen. SwiftUI and Swift own application orchestration, security-scoped file import, persistence, Keychain access, and workflow state. Rust owns untrusted binary parsing and will later host modern device protocols. C++ is limited to the signing-engine adapter. Swift never consumes Rust references or C++ classes; both native layers expose versioned C ABIs.

The local Swift package graph is acyclic:

```text
IPADomain
├── IPALibrary
├── IPAInspection
├── DeviceKit
├── PersistenceKit
└── SigningKit ── SecurityKit
```

`IPADomain` contains stable value types and no infrastructure. `IPALibrary` owns import storage and archive policy. `IPAInspection` assembles metadata and delegates Mach-O parsing through the native boundary. `SigningKit` plans graph-ordered signing and delegates execution through the signer ABI. `DeviceKit` will orchestrate pairing, transport, AFC, installation, and refresh verification without leaking protocol implementation into UI code.

An imported IPA is immutable. Its canonical location is `Application Support/Library/<UUID>/original.ipa`; metadata, derived artifacts, and disposable work live in sibling `metadata/`, `artifacts/`, and `work/` directories. Every signed artifact records the source identifier and source SHA-256. No operation rewrites `original.ipa`.

`ios/project.yml` is the only Xcode project source. GitHub Actions generates `ios/IPAManager.xcodeproj`; generated projects and native artifacts are not committed. The Chromebook is limited to editing, Git, and lightweight static checks. All dependency resolution and compilation occurs on CI runners.
