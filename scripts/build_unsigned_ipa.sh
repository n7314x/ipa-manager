#!/usr/bin/env bash
set -euo pipefail

if [[ "${CI:-}" != "true" ]]; then
  echo "Unsigned device builds are CI-only for this repository." >&2
  exit 2
fi

project_path="${PROJECT_PATH:-ios/IPAManager.xcodeproj}"
scheme="${SCHEME:-IPAManager}"
configuration="${CONFIGURATION:-Release}"
ipa_name="${IPA_NAME:-IPAManager.ipa}"
output_dir="${1:-${OUTPUT_DIR:-}}"
expected_bundle_id="${EXPECTED_BUNDLE_ID:-xyz.n9007314.ipamanager}"
expected_display_name="${EXPECTED_DISPLAY_NAME:-IPA Manager}"
expected_minimum_os="${EXPECTED_MINIMUM_OS:-17.0}"

case "$output_dir" in
  ""|/|.|..|~) echo "Refusing unsafe output directory: $output_dir" >&2; exit 2 ;;
esac
case "$ipa_name" in
  *.ipa) ;;
  *) echo "IPA_NAME must be a filename ending in .ipa" >&2; exit 2 ;;
esac
if [[ "$ipa_name" == */* ]]; then
  echo "IPA_NAME must not contain path separators" >&2
  exit 2
fi

for tool in xcodebuild xcrun ditto zip unzip plutil lipo codesign shasum; do
  command -v "$tool" >/dev/null || { echo "Required Apple build tool is unavailable: $tool" >&2; exit 2; }
done
test -f "$project_path/project.pbxproj"
test -f ios/IPAManager/Resources/Info.plist

mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
work_parent="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
work_dir="$(mktemp -d "$work_parent/ipa-manager-ios.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT

archive_path="$work_dir/IPAManager.xcarchive"
staging_path="$work_dir/ipa-staging"
verification_path="$work_dir/ipa-verification"
ipa_path="$output_dir/$ipa_name"
build_log="$output_dir/IPAManager-xcodebuild.log"
metadata_path="$output_dir/build-metadata.json"

plutil -lint ios/IPAManager/Resources/Info.plist
xcodebuild_args=(
  archive
  -project "$project_path"
  -scheme "$scheme"
  -configuration "$configuration"
  -archivePath "$archive_path"
  -sdk iphoneos
  -destination "generic/platform=iOS"
  -derivedDataPath "$work_dir/DerivedData"
  -clonedSourcePackagesDirPath "$work_dir/SourcePackages"
  ONLY_ACTIVE_ARCH=NO
  SKIP_INSTALL=NO
  CODE_SIGNING_ALLOWED=NO
  CODE_SIGNING_REQUIRED=NO
  CODE_SIGN_IDENTITY=
  DEVELOPMENT_TEAM=
)
xcodebuild "${xcodebuild_args[@]}" | tee "$build_log"

app_path="$archive_path/Products/Applications/IPAManager.app"
info_plist="$app_path/Info.plist"
test -d "$app_path"
test -f "$info_plist"
plutil -lint "$info_plist"

plist_buddy=/usr/libexec/PlistBuddy
executable_name="$("$plist_buddy" -c 'Print :CFBundleExecutable' "$info_plist")"
bundle_identifier="$("$plist_buddy" -c 'Print :CFBundleIdentifier' "$info_plist")"
display_name="$("$plist_buddy" -c 'Print :CFBundleDisplayName' "$info_plist")"
version="$("$plist_buddy" -c 'Print :CFBundleShortVersionString' "$info_plist")"
build_version="$("$plist_buddy" -c 'Print :CFBundleVersion' "$info_plist")"
minimum_os="$("$plist_buddy" -c 'Print :MinimumOSVersion' "$info_plist")"
executable_path="$app_path/$executable_name"

test "$bundle_identifier" = "$expected_bundle_id"
test "$display_name" = "$expected_display_name"
test "$minimum_os" = "$expected_minimum_os"
test -n "$version"
test -n "$build_version"
test -x "$executable_path"
case " $(lipo -archs "$executable_path") " in
  *" arm64 "*) ;;
  *) echo "The app executable lacks the required arm64 device slice." >&2; exit 1 ;;
esac
if codesign -d "$app_path" >/dev/null 2>&1 || [[ -d "$app_path/_CodeSignature" ]]; then
  echo "The canonical app unexpectedly contains a code signature." >&2
  exit 1
fi
if find "$app_path" -name embedded.mobileprovision -print -quit | grep -q .; then
  echo "The canonical app unexpectedly contains a provisioning profile." >&2
  exit 1
fi

mkdir -p "$staging_path/Payload" "$verification_path"
ditto "$app_path" "$staging_path/Payload/IPAManager.app"
rm -f -- "$ipa_path"
(
  cd "$staging_path"
  zip -qry "$ipa_path" Payload
)
unzip -tq "$ipa_path"
unzip -q "$ipa_path" -d "$verification_path"
top_level_count="$(find "$verification_path" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
test "$top_level_count" = "1"
test -d "$verification_path/Payload"
app_count="$(find "$verification_path/Payload" -mindepth 1 -maxdepth 1 -type d -name '*.app' | wc -l | tr -d ' ')"
test "$app_count" = "1"
test -f "$verification_path/Payload/IPAManager.app/Info.plist"
test ! -e "$verification_path/Payload/IPAManager.app/embedded.mobileprovision"

ipa_size="$(stat -f '%z' "$ipa_path")"
ipa_sha256="$(shasum -a 256 "$ipa_path" | awk '{print $1}')"
commit_sha="${GITHUB_SHA:-$(git rev-parse HEAD)}"
release_timestamp="${RELEASE_TIMESTAMP:-$(git show -s --format=%cI "$commit_sha")}"
xcode_version="$(xcodebuild -version | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
ios_sdk_version="$(xcrun --sdk iphoneos --show-sdk-version)"
executable_architectures="$(lipo -archs "$executable_path")"

export IPA_METADATA_PATH="$metadata_path" IPA_BUNDLE_ID="$bundle_identifier"
export IPA_DISPLAY_NAME="$display_name" IPA_VERSION="$version" IPA_BUILD_VERSION="$build_version"
export IPA_MINIMUM_OS="$minimum_os" IPA_FILENAME="$ipa_name" IPA_SIZE="$ipa_size" IPA_SHA256="$ipa_sha256"
export IPA_COMMIT_SHA="$commit_sha" IPA_RELEASE_TIMESTAMP="$release_timestamp"
export IPA_XCODE_VERSION="$xcode_version" IPA_SDK_VERSION="$ios_sdk_version" IPA_ARCHITECTURES="$executable_architectures"
python3 - <<'PY'
import json
import os
from pathlib import Path

metadata = {
    "schemaVersion": 1,
    "bundleIdentifier": os.environ["IPA_BUNDLE_ID"],
    "displayName": os.environ["IPA_DISPLAY_NAME"],
    "version": os.environ["IPA_VERSION"],
    "buildVersion": os.environ["IPA_BUILD_VERSION"],
    "minimumOSVersion": os.environ["IPA_MINIMUM_OS"],
    "ipaFilename": os.environ["IPA_FILENAME"],
    "ipaSize": int(os.environ["IPA_SIZE"]),
    "ipaSHA256": os.environ["IPA_SHA256"],
    "commitSHA": os.environ["IPA_COMMIT_SHA"],
    "releaseTimestamp": os.environ["IPA_RELEASE_TIMESTAMP"],
    "xcodeVersion": os.environ["IPA_XCODE_VERSION"],
    "iOSSDKVersion": os.environ["IPA_SDK_VERSION"],
    "executableArchitectures": os.environ["IPA_ARCHITECTURES"].split(),
    "signing": "unsigned",
}
Path(os.environ["IPA_METADATA_PATH"]).write_text(
    json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8"
)
PY

echo "Unsigned IPA: $ipa_path"
echo "Version/build: $version ($build_version)"
echo "IPA size: $ipa_size bytes"
echo "IPA SHA-256: $ipa_sha256"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "ipa_path=$ipa_path"
    echo "metadata_path=$metadata_path"
    echo "version=$version"
    echo "build_version=$build_version"
    echo "ipa_size=$ipa_size"
    echo "ipa_sha256=$ipa_sha256"
  } >> "$GITHUB_OUTPUT"
fi
