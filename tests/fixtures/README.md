# Test fixtures

Only synthetic, redistributable fixtures may be added. Never add real IPAs, certificates,
private keys, passwords, provisioning profiles, authentication tokens, or pairing records.

Future adversarial fixtures should cover traversal, absolute paths, symlinks, duplicate and
Unicode-confusable paths, oversized entries, ZIP bombs, malformed ZIP metadata, malformed
plists/Mach-O files, multiple top-level apps, frameworks, extensions, and expired profiles.

Phase 1A Swift tests generate their minimal valid ZIP-based IPA at runtime with the repository's
exact ZIPFoundation dependency. No binary IPA fixture is stored here.
