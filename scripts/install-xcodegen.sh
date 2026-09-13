#!/usr/bin/env bash
set -euo pipefail

if [[ "${CI:-}" != "true" || -z "${RUNNER_TEMP:-}" || -z "${GITHUB_PATH:-}" ]]; then
  echo "XcodeGen installation is supported only on an ephemeral CI runner." >&2
  exit 2
fi

version="2.46.0"
expected_sha256="4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806"
archive="$RUNNER_TEMP/xcodegen-$version.zip"
install_root="$RUNNER_TEMP/xcodegen-$version"
curl --fail --location --retry 3 --output "$archive" \
  "https://github.com/yonaskolb/XcodeGen/releases/download/$version/xcodegen.zip"
echo "$expected_sha256  $archive" | shasum -a 256 --check
mkdir -p "$install_root"
unzip -oq "$archive" -d "$install_root"
binary="$(find "$install_root" -type f -name xcodegen -print -quit)"
test -n "$binary"
chmod 755 "$binary"
echo "$(dirname "$binary")" >> "$GITHUB_PATH"
"$binary" --version
