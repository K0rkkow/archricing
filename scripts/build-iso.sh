#!/usr/bin/env bash
# scripts/build-iso.sh — point d'entrée officiel. Idempotent.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ $EUID -eq 0 ]] || exec sudo -- "$0" "$@"
bash "$ROOT/iso/build.sh" "$@"
