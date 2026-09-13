# Unsigned IPA releases

The canonical release workflow runs on `xcode-27`, generates the Xcode project, and calls `scripts/build_unsigned_ipa.sh`. The script creates an unsigned device archive with all signing flags disabled, using a unique `RUNNER_TEMP` workspace and no GitHub signing secrets.

The archive product must be `IPAManager.app` with bundle ID `xyz.n9007314.ipamanager`, display name `IPA Manager`, non-empty version/build values, iOS minimum `17.0`, an executable arm64 slice, no valid code signature, and no `embedded.mobileprovision`. It is staged only as `Payload/IPAManager.app`, ZIP-tested, extracted again, and structurally revalidated.

CI uploads `IPAManager.ipa` with `build-metadata.json`, including byte size, SHA-256, commit, deterministic commit timestamp, SDK/Xcode versions, and architectures. The Xcode build log is uploaded only on failure. The artifact is intended for download and installation through iLoader after the user supplies appropriate signing outside this canonical unsigned build.

This flow is adapted from the private Location Suite first-party workflow. It does not copy application code and does not depend on SideStore or Feather release logic.
