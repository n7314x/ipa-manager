# Pairing

Pairing is deferred with direct installation. Future pairing material is treated as credential data: records are protected at rest, scoped to a device identifier, never written to logs, and never serialized into ordinary JSON or SwiftData. Key material should use Keychain where practical; protected files must use complete file protection and a Keychain-held encryption key.

`DeviceKit` owns pairing orchestration while `SecurityKit` owns storage. Rust may implement lockdownd, RSD, RemoteXPC, and transport details behind the C ABI. Raw pairing records must not cross into SwiftUI state or analytics. Removing a paired device must also remove its protected record and invalidate cached sessions.

Location Suite is the preferred first-party design reference for device-service work. SideStore (AGPL) and Feather (GPL) are architecture references only; no copyleft implementation is copied.
