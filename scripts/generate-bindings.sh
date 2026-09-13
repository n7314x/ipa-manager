#!/usr/bin/env bash
set -euo pipefail
if [[ "${CI:-}" != "true" ]]; then
  echo "Binding generation is CI-only for this repository." >&2
  exit 2
fi
command -v cbindgen >/dev/null || { echo "cbindgen is not installed in this CI job" >&2; exit 2; }
cbindgen --config native/rust/crates/native-ffi/cbindgen.toml \
  --crate native-ffi \
  --output "${RUNNER_TEMP:?RUNNER_TEMP is required}/IPAManagerNative.generated.h" \
  native/rust/crates/native-ffi
