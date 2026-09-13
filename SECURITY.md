# Security policy

Please report vulnerabilities privately to the repository owner rather than opening a public issue. Include affected revision, reproduction conditions, and impact, but do not include real certificates, passwords, keys, tokens, Apple credentials, or pairing records.

Imported archives are hostile input. Changes affecting ZIP extraction, plist/Mach-O parsing, code signing, Keychain storage, pairing, or device transport require adversarial tests and documentation updates. See `docs/security/` for the current policy and known deferred boundaries.
