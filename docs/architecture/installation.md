# Installation

Initial releases stop at signing and export. The supported path is `IPA Manager → signed IPA → iLoader`; direct device installation is intentionally unavailable.

The future direct path is `signed IPA → protected pairing material → LocalDevVPN/StosVPN-style tunnel → device-service transport → AFC/PublicStaging → installation_proxy or a pinned idevice helper → installed-state verification`. These stages remain behind `DeviceKit` protocols so transport and protocol changes do not affect the UI or signing planner. Capabilities requiring newer iOS behavior must be runtime-gated; the app-wide deployment target remains iOS 17.0.

When device work begins, `jkcoxson/idevice` is the preferred MIT dependency. Its pre-0.2 API is unstable, so the exact current release or commit must be rechecked and pinned at integration time. No placeholder workflow should claim installation support before an end-to-end verified implementation exists.
