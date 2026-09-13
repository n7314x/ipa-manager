# Refresh

Automatic refresh is deferred. A scheduled attempt, successful signature operation, or successful upload is not refresh success.

The invariant is: a refreshed artifact was generated; installation/update completed; installed app state was read again from the device; and the newly observed expiry is later than the previously observed expiry. Only after all four conditions hold may an installation record be marked refreshed. Failures preserve the old verified state and record a redacted audit event.

Future scheduling policy belongs in Swift orchestration and persists only configuration, timestamps, status, and history. Credentials remain in Keychain/protected storage. Background execution limits and runtime device-service availability must be modeled explicitly rather than hidden behind optimistic status.
