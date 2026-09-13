#!/usr/bin/env bash
set -euo pipefail

if [[ "${CI:-}" != "true" ]]; then
  echo "XCFramework generation is CI-only for this repository." >&2
  exit 2
fi

native_output="${NATIVE_OUTPUT_DIR:?NATIVE_OUTPUT_DIR is required}"
framework_output="${XCFRAMEWORK_OUTPUT_DIR:?XCFRAMEWORK_OUTPUT_DIR is required}"
build_root="${RUNNER_TEMP:?RUNNER_TEMP is required}/ipa-manager-cpp-ios"
header_root="$RUNNER_TEMP/ipa-manager-native-headers"
mkdir -p "$framework_output" "$header_root/rust" "$header_root/signer"
cp native/include/IPAManagerNative.h native/include/IPAInspector.h native/include/IPADevice.h "$header_root/rust/"
cp native/include/IPASigner.h "$header_root/signer/"

cmake -S native/signing-cpp -B "$build_root/device" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
  -DIPA_SIGNING_BUILD_TESTS=OFF
cmake --build "$build_root/device" --config Release --parallel 2

cmake -S native/signing-cpp -B "$build_root/simulator" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
  -DIPA_SIGNING_BUILD_TESTS=OFF
cmake --build "$build_root/simulator" --config Release --parallel 2

xcodebuild -create-xcframework \
  -library "$native_output/rust/device/libnative_ffi.a" -headers "$header_root/rust" \
  -library "$native_output/rust/simulator/libnative_ffi.a" -headers "$header_root/rust" \
  -output "$framework_output/IPAManagerNative.xcframework"
xcodebuild -create-xcframework \
  -library "$build_root/device/libipa_signing_bridge.a" -headers "$header_root/signer" \
  -library "$build_root/simulator/libipa_signing_bridge.a" -headers "$header_root/signer" \
  -output "$framework_output/IPASigningBridge.xcframework"
