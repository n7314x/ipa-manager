# Test fixtures

Only synthetic, redistributable fixtures may be added. Never add real IPAs, certificates,
private keys, passwords, provisioning profiles, authentication tokens, or pairing records.

Phase 1B-A tests generate adversarial archive descriptors and tiny ZIP/property-list fixtures for
traversal, absolute paths, symlinks, duplicate normalized paths, resource limits, ZIP-bomb ratios,
malformed metadata, multiple top-level apps, frameworks, extensions, nested apps, icons, and
provisioning summaries. Mach-O fixtures remain deferred to Phase 1B-B.

Swift tests generate their minimal ZIP-based IPAs at runtime with the repository's exact
ZIPFoundation dependency. No binary IPA, provisioning profile, or extracted application fixture
is stored here.
