#!/usr/bin/env bash
# scripts/clean-build.sh — nettoie work/, out/ et backups (sûr : ne touche jamais aux sources).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rm -rf "$ROOT/work" "$ROOT/out"
find "$ROOT" -name '*.bak-*' -not -path "$ROOT/.git/*" -delete 2>/dev/null || true
echo "Nettoyé : work/ out/ backups."
