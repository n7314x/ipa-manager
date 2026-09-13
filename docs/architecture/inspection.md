# Inspection

Inspection starts only after the security-scoped source has been copied into app-controlled storage and hashed. Archive validation precedes extraction. Extraction occurs in a unique temporary workspace which is removed after the operation, and every later path is relative to that workspace.

The pipeline is: validate ZIP metadata and limits; safely extract with ZIPFoundation `0.9.20`; require exactly one top-level `Payload/*.app`; parse bounded plist data; build a component graph; and send executable bytes to Rust for Mach-O parsing with goblin. Native parsers receive byte buffers with explicit lengths and return value summaries or status codes. Malformed data is an ordinary error, never a process crash.

The component graph identifies the main app, extensions, frameworks, dylibs, and any supported nested applications. Inspection does not mutate the archive and does not imply the IPA is signable. Entitlement and provisioning-profile results are snapshots used later by the signing compatibility planner.
