# iOS builds

GitHub Actions on `xcode-27` is the source of truth. `ios/project.yml` declares the app and seven local Swift packages. CI downloads XcodeGen `2.46.0` into `RUNNER_TEMP`, verifies its published SHA-256, generates `ios/IPAManager.xcodeproj`, resolves the exact ZIPFoundation dependency, tests each package, and builds the generic iOS simulator target with signing disabled. The generated project is never committed.

Native iOS CI pins Rust and adds device arm64 plus Apple-silicon simulator targets on the runner. Cargo, CMake, libraries, and XCFrameworks are all written under `RUNNER_TEMP` and uploaded as ephemeral artifacts. These native artifacts prove ABI scaffolds compile; they do not prove signing or installation features work and are not linked into the app yet.

When CI fails, inspect the environment/version step, package resolution, and uploaded build log. Do not reproduce the build on the Chromebook by installing Apple or Rust tooling.
