# Threat model

IPA files, provisioning profiles, plist documents, Mach-O binaries, filenames, and device responses are untrusted. An attacker may attempt traversal, absolute-path writes, symlink escapes, duplicate/confusable paths, malformed metadata, parser crashes, excessive allocation, decompression bombs, or misleading bundle layouts. The app sandbox is not a substitute for validating these inputs.

Security goals are to preserve the immutable source IPA, confine extraction to a disposable workspace, bound CPU/disk/memory exposure, avoid native-language undefined behavior across FFI, protect signing and pairing secrets, and provide audit history without secret leakage. A failed operation must not leave a partially signed artifact presented as valid.

Out of scope for this foundation are Apple ID authentication, automatic provisioning, direct device installation, refresh scheduling, and an embedded signing engine. Their unavailable states are explicit. No logs may contain P12 passwords, private keys, Apple credentials, tokens, or pairing-record contents.

Dependency licensing is also a supply-chain boundary. ZIPFoundation, zsign, idevice, and XcodeGen are MIT. SideStore is AGPL and Feather is GPL; they may inform architecture but their implementation is not imported without a separate licensing decision.
