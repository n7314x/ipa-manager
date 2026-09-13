# IPA validation policy

Validation occurs before and during extraction. ZIPFoundation is pinned exactly to `0.9.20`, which includes the path-escape and symlink-containment fixes introduced in the 0.9.18 line. A broad semver range is not acceptable.

The validator rejects absolute paths, `..` or `.` components, backslash path ambiguity, NULs, duplicate Unicode-normalized paths, symlinks in the initial conservative policy, excessive entry count, oversized individual entries, excessive total uncompressed bytes, invalid size metadata, and excessive compression ratios. Totals use overflow-aware arithmetic. Extraction must additionally verify each destination remains under the temporary root before writing.

After extraction, exactly one direct `Payload/*.app` is required. `Info.plist`, provisioning profiles, and Mach-O inputs are size-bounded and parsed as fallible data. Unexpected multiple apps, malformed plist values, unsupported bundle nesting, or native parser errors fail the import. The temporary tree is deleted; the source `original.ipa` remains unchanged.

The current Swift package establishes policy primitives but intentionally defers the ZIPFoundation extraction implementation until adversarial fixtures exercise path, symlink, and resource-limit behavior.
