#!/usr/bin/env bash
# DEPRECATED — internal compatibility shim. Official entry point: ./build.sh
echo "DEPRECATED: scripts/build-iso.sh is internal — running ./build.sh instead." >&2
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$ROOT/build.sh" "$@"
