#!/usr/bin/env bash
set -euo pipefail

if [[ "${CI:-}" != "true" ]]; then
  echo "Rust Apple-target builds are CI-only for this repository." >&2
  exit 2
fi

output_dir="${NATIVE_OUTPUT_DIR:?NATIVE_OUTPUT_DIR is required}"
target_dir="${RUNNER_TEMP:?RUNNER_TEMP is required}/ipa-manager-rust-target"
mkdir -p "$output_dir/rust/device" "$output_dir/rust/simulator"
export CARGO_TARGET_DIR="$target_dir"
cargo build --manifest-path native/rust/Cargo.toml --release --package native-ffi --target aarch64-apple-ios
cargo build --manifest-path native/rust/Cargo.toml --release --package native-ffi --target aarch64-apple-ios-sim
cp "$target_dir/aarch64-apple-ios/release/libnative_ffi.a" "$output_dir/rust/device/"
cp "$target_dir/aarch64-apple-ios-sim/release/libnative_ffi.a" "$output_dir/rust/simulator/"
