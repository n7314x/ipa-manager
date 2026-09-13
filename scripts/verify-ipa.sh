#!/usr/bin/env bash
set -euo pipefail

if [[ "${CI:-}" != "true" ]]; then
  echo "Canonical IPA verification is CI-only for this repository." >&2
  exit 2
fi

ipa_path="${1:?usage: scripts/verify-ipa.sh PATH_TO_IPA}"
test -f "$ipa_path"
command -v unzip >/dev/null
unzip -tq "$ipa_path"
work_parent="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
work_dir="$(mktemp -d "$work_parent/ipa-verify.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT
unzip -q "$ipa_path" -d "$work_dir"
top_level_count="$(find "$work_dir" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
test "$top_level_count" = "1"
test -d "$work_dir/Payload"
app_count="$(find "$work_dir/Payload" -mindepth 1 -maxdepth 1 -type d -name '*.app' | wc -l | tr -d ' ')"
test "$app_count" = "1"
if find "$work_dir/Payload" -name embedded.mobileprovision -print -quit | grep -q .; then
  echo "IPA contains an embedded provisioning profile" >&2
  exit 1
fi
echo "IPA ZIP and canonical Payload structure are valid: $ipa_path"
