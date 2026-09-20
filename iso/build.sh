#!/usr/bin/env bash
# DEPRECATED — internal compatibility shim. Official entry point: ./build.sh
echo "DEPRECATED: iso/build.sh is internal — running ./build.sh instead." >&2
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$HERE/../build.sh" "$@"
