#!/usr/bin/env bash
set -euo pipefail
echo "package-ipa.sh delegates to the canonical archive-based build." >&2
exec "$(dirname "$0")/build_unsigned_ipa.sh" "$@"
