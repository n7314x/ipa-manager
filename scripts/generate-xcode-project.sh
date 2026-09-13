#!/usr/bin/env bash
set -euo pipefail

if [[ "${CI:-}" != "true" ]]; then
  echo "Xcode project generation is CI-only for this repository." >&2
  exit 2
fi

command -v xcodegen >/dev/null || { echo "xcodegen is required in CI" >&2; exit 2; }
test -f ios/project.yml
(
  cd ios
  xcodegen generate --spec project.yml
)
test -f ios/IPAManager.xcodeproj/project.pbxproj
