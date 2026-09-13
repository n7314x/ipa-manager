# Linux/Chromebook development

This Chromebook checkout is for editing, review, and Git only. Do not run Cargo, CMake, Swift, Xcode, XcodeGen, or dependency builds here; do not install toolchains or Apple targets; and do not download dependency repositories, XCFrameworks, DerivedData, or target directories.

Allowed checks are lightweight and non-resolving: `git status --short`, `git diff --check`, `git diff`, `rg`, `find`, shell parsing with `bash -n`, plist/XML parsing with Python’s standard library, and JSON parsing with `python3 -m json.tool`. Build scripts refuse local execution where appropriate.

Linux CI uses `ubuntu-24.04`, installs only CMake/Ninja, pins Rust `1.98.1`, and runs rustfmt, clippy, check, tests, plus C++ configure/build/tests. Build directories are under `RUNNER_TEMP`. Cargo.lock is not blanket-ignored and should be committed once dependency resolution is validated and stabilized in CI.
