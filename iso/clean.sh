#!/usr/bin/env bash
# clean.sh — nettoie work/ et out/ (sûr : ne touche jamais au repo).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
rm -rf "$ROOT/work" "$ROOT/out"
echo "Nettoyé."
