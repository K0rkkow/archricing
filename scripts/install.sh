#!/usr/bin/env bash
# scripts/install.sh — installation manuelle hors Calamares (VM/test). Idempotent.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
msg(){ printf '\033[1;35m[archricing]\033[0m %s\n' "$*"; }
msg "Sync + installation paquets core/desktop/perso…"
sudo pacman -Syu --needed --noconfirm $(grep -h -vE '^\s*(#|$)' "$ROOT/packages/core/packages.txt" "$ROOT/packages/desktop/packages.txt" "$ROOT/packages/personalization/packages.txt" | sort -u)
bash "$ROOT/scripts/post-install.sh"
msg "Optionnel sécurité : archricing settings -> Security Toolkit (avec avertissement légal)."
