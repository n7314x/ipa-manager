# Native boundaries

`native/include/` contains the audited public C ABI. Status values use fixed-width integer
types; buffers and UTF-8 strings are borrowed length-delimited views; functions retain and
free nothing unless a future API explicitly documents otherwise. Rust panics and C++
exceptions must never cross these functions.

`native/rust/` contains the `ipa-inspect`, dependency-light `device-core`, and `native-ffi`
crates. The current exported inspector only distinguishes valid thin/fat Mach-O input; richer
inspection is deferred. Device services return unsupported and do not include idevice yet.

`native/signing-cpp/` validates the signer request ABI and returns unsupported. It contains no
signing engine. The later zsign-style integration must remain behind this interface and must
be proven as an embedded iOS library in CI before the app links it.

CI writes all Cargo/CMake products to `RUNNER_TEMP`, packages separate Rust and signer
XCFrameworks, and uploads them as ephemeral artifacts. `native/artifacts/` is reserved for
future reviewed generated products and remains ignored.
