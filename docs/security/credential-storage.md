# Credential storage

P12 import will use `SecPKCS12Import` and Apple Keychain. Password bytes exist only long enough to perform the import/use operation, are held in an erasable buffer, and are cleared immediately afterward. Private keys and identities remain in Keychain. SwiftData may store a Keychain persistent reference plus non-secret certificate metadata; it must not store private key material or passwords.

Provisioning profiles are not private keys and may live as application files, but they receive normal sandbox isolation, atomic writes, and file protection. Pairing records are credentials and must not be stored in plain JSON, UserDefaults, logs, crash breadcrumbs, or unprotected SwiftData fields.

Redaction is mandatory for P12 passwords, private-key bytes, Apple credentials, authentication tokens, and complete pairing records. Errors exposed to UI or audit history should contain stable categories and safe context, never raw credential payloads.
