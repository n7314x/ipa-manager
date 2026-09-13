# Signing

V1 accepts a user-supplied P12 identity and one or more mobileprovision files. It does not authenticate to Apple or create provisioning profiles. `SigningKit` owns policy and planning; a stable C ABI owns the execution boundary; a future embedded zsign-style implementation performs signing. The current bridge returns an explicit unsupported status.

Signing is graph ordered, not recursive “deep signing.” Frameworks, dylibs, extensions, and other nested executable bundles are signed before their containing bundle; the main app is last. Each extension may require a distinct profile. Effective entitlements are derived from the intersection of original entitlements, profile-authorized entitlements, and IPA Manager policy. Incompatibilities must be reported before mutation begins.

The signer works on a disposable copy under `work/` and writes a new IPA under `artifacts/`. It never modifies `original.ipa`. ABI inputs are borrowed byte/string views with lengths. The callee retains and frees nothing, C++ exceptions are caught, Rust panics are caught, and the caller clears password bytes immediately after use.

zsign is MIT and is the preferred behavior reference, but its desktop build is not assumed to be embeddable on iOS. A later CI-only integration spike will pin source and fetch it into `RUNNER_TEMP`. Feather (GPL) may be studied for architecture only; its source must not be copied into this repository.
