# Contributing

Keep changes inside the established module boundaries and keep the dependency graph acyclic. New third-party dependencies require a concrete need, an exact pin when APIs or security demand it, and a license review. Never copy SideStore (AGPL) or Feather (GPL) implementation into this project.

On the Chromebook, restrict validation to lightweight text checks. Push a branch and let GitHub Actions perform builds and tests. Do not commit generated `.xcodeproj`, build products, native artifacts, credentials, imported IPAs, or pairing records.

Native APIs must remain C-compatible: fixed-width values, length-delimited byte/UTF-8 views, caller-documented ownership, opaque handles when needed, and explicit status codes. Panics and C++ exceptions must be caught before crossing ABI boundaries.
