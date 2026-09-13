#!/usr/bin/env bash
set -euo pipefail
if [[ "${CI:-}" != "true" ]]; then
  echo "Native builds are CI-only for this repository." >&2
  exit 2
fi
export CARGO_TARGET_DIR="${RUNNER_TEMP:?RUNNER_TEMP is required}/ipa-manager-rust-target"
cargo test --manifest-path native/rust/Cargo.toml --workspace
cmake -S native/signing-cpp -B "$RUNNER_TEMP/ipa-manager-signing" -DIPA_SIGNING_BUILD_TESTS=ON
cmake --build "$RUNNER_TEMP/ipa-manager-signing" --parallel 2
ctest --test-dir "$RUNNER_TEMP/ipa-manager-signing" --output-on-failure
