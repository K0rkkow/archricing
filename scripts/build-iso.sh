#!/usr/bin/env bash
# scripts/build-iso.sh — INTERNE (détail d'implémentation).
# Ne pas appeler directement : point d'entrée officiel = ./build.sh (racine).
# Orchestre iso/build.sh avec élévation sudo si nécessaire.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ $EUID -eq 0 ]] || exec sudo -- "$0" "$@"
bash "$ROOT/iso/build.sh" "$@"
