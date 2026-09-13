# IPA validation policy

ZIPFoundation is pinned exactly to `0.9.20`, which includes the path-escape and symlink-containment fixes introduced in the 0.9.18 line. A broad semver range is not acceptable.

Phase 1A first copies a selected security-scoped file-provider URL into an app-controlled temporary workspace, then releases provider access. It rejects non-regular files, empty files, filenames without an `.ipa` extension, and source archives larger than 4 GiB. The managed copy must open through ZIPFoundation and contain exactly one direct `Payload/*.app` path. Import validation reads ZIP central-directory metadata only; it does not extract the archive.

The validator rejects absolute paths, `..` or `.` components, backslash path ambiguity, NULs, duplicate Unicode-normalized paths, symlinks in the initial conservative policy, excessive entry count, oversized individual entries, excessive total uncompressed bytes, invalid size metadata, and excessive compression ratios. Totals use overflow-aware arithmetic.

Phase 1B extraction must additionally verify each destination remains under the temporary root before writing. After extraction, `Info.plist`, provisioning profiles, and Mach-O inputs will be size-bounded and parsed as fallible data. Unexpected multiple apps, malformed plist values, unsupported bundle nesting, or native parser errors will fail inspection. Temporary trees are deleted; the source `original.ipa` remains unchanged.

The current Swift package intentionally defers ZIPFoundation extraction and full adversarial archive validation until Phase 1B fixtures exercise path, symlink, and resource-limit behavior.
