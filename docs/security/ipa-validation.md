# IPA validation policy

ZIPFoundation is pinned exactly to `0.9.20`, which includes the path-escape and symlink-containment fixes introduced in the 0.9.18 line. A broad semver range is not acceptable.

Phase 1A first copies a selected security-scoped file-provider URL into an app-controlled temporary workspace, then releases provider access. It rejects non-regular files, empty files, filenames without an `.ipa` extension, and source archives larger than 4 GiB. The managed copy must open through ZIPFoundation and contain exactly one direct `Payload/*.app` path. The file-provider original remains untouched; all later work reads the immutable app-managed `original.ipa`.

Phase 1B-A repeats full central-directory preflight immediately before extraction. No entry is written until every entry has passed. The validator rejects:

- absolute POSIX paths and Windows drive paths;
- backslashes, control characters, empty path components, and `.` or `..` components at any depth;
- duplicate paths after canonical Unicode normalization, conservative case folding, and removal of a directory marker;
- file/directory collisions where a declared file is also an ancestor of another destination;
- symbolic links (ZIPFoundation 0.9.20 exposes these through `Entry.type`); other special Unix entry modes are not materialized as links by the selected API;
- archives exceeding an entry, declared-size, path-length, nesting, or compression-ratio limit;
- zero compressed size paired with nonzero uncompressed size;
- missing `Payload`, no immediate `Payload/*.app`, or multiple immediate root apps;
- unreadable archive entries, central-directory count/bounds mismatches, CRC failures, declared/actual extracted-size mismatches, or extracted items whose type changes.

Nested apps such as `Payload/Main.app/Watch/WatchApp.app` do not count as additional root apps. Unrelated top-level metadata such as an Xcode archive's conventional auxiliary files may remain, but it never changes root-app selection.

## Numeric limits

All limits live in `ArchiveSafetyPolicy`; extraction and import validation use the same policy.

| Limit | Value | Rationale |
| --- | ---: | --- |
| Compressed source IPA | 4 GiB | Retains the Phase 1A device-storage boundary. |
| Archive entries | 10,000 | Accommodates resource-heavy apps while bounding inode and iteration work. |
| Total declared uncompressed size | 8 GiB | Allows ordinary large iOS apps while bounding workspace consumption. |
| Free-space safety reserve | 512 MiB | Preserves working capacity beyond the archive's declared extraction footprint. |
| One declared uncompressed entry | 512 MiB | Prevents a single resource from monopolizing storage or decompression time. |
| Compression ratio | 200:1 | Rejects highly suspicious deflate expansion in addition to absolute limits. |
| UTF-8 archive path | 1,024 bytes | Bounds decoding and filesystem path work. |
| Path nesting | 32 components | Bounds pathological directory trees. |
| Root or component `Info.plist` | 4 MiB | Property lists are metadata, not arbitrary app assets. |
| Persisted metadata string | 1,024 UTF-8 bytes | Prevents hostile plist strings from becoming oversized UI/database values. |
| Icon plist traversal | 4,096 values and 128 declarations | Bounds recursive work and candidate matching for adversarial icon dictionaries. |
| `UIDeviceFamily` values | 16 | Bounds a small platform metadata field. |
| `embedded.mobileprovision` | 4 MiB | Profiles are small signed metadata containers. |
| Candidate icon | 32 MiB | Bounds image probing and the one-file cache. |
| Candidate icon dimensions | 4,096 px per axis; 16,777,216 pixels total | Rejects small PNG files that declare impractically large decoded images. |
| Provisioning entitlement values | 4,096 | Bounds recursive entitlement conversion; recursion is separately capped at 16 levels. |

Extraction takes place in a unique `Library/<UUID>/work/inspection-<UUID>/extracted` directory. Destination containment compares standardized path components, not string prefixes, so `/tmp/work-evil` cannot satisfy containment for `/tmp/work`. Symlinks are rejected before extraction and extracted destinations are resolved and checked again. ZIP CRC checking stays enabled, and actual regular-file sizes are compared with their declarations. Cancellation is checked between entries and pipeline stages.

After preflight has validated and totaled every declared uncompressed entry, but before the extractor is invoked, inspection queries `volumeAvailableCapacityForImportantUsage` for the volume containing that unique workspace. Available capacity must be at least the overflow-checked sum of the preflight total and the centralized 512 MiB reserve. The already-managed source IPA is not counted again. A missing or failed capacity query is treated as insufficient storage, and no extraction begins. The app privacy manifest declares required-reason API category `NSPrivacyAccessedAPICategoryDiskSpace` with reason `E174.1` for this user-initiated write-capacity check.

The workspace is removed on success, failure, and cancellation. Stale `inspection-*` directories for the same managed item are removed before a new attempt. The extracted application is never cached. Only bounded derived metadata and, when declared and usable, one selected PNG icon are retained under `metadata/`.

Binary and XML property lists are parsed with `PropertyListSerialization`. Embedded provisioning-profile presence is recorded on every platform. Apple's CMS decoder is used on macOS, where it is public; it is SPI-only on iOS, so the device app reports decoding as unavailable instead of calling private API. The decoding interface extracts safe summary metadata when a public decoder is available. It stores device counts but never the profile's device-identifier list, raw CMS payload, or private data. CMS decoding is metadata parsing and does not assert profile trust or signing validity.

Mach-O files and embedded code-signature entitlements are not inspected in Phase 1B-A. Their state is explicitly `unavailable`; native Rust inspection remains Phase 1B-B.
