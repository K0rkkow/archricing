#!/usr/bin/env bash
# scripts/validate-menu.sh — garantit "aucune entrée cassée" : chaque .desktop du menu
# Security dont le binaire Exec est absent est déplacé dans <dir>/disabled/ (journalisé).
# Appelé par post-install.sh (EDITION=security). Idempotent.
set -uo pipefail
MENU_DIR="${1:-/usr/share/applications/archricing-security}"
DISABLED="$MENU_DIR/disabled"
mkdir -p "$DISABLED"
n_ok=0; n_off=0
for d in "$MENU_DIR"/archricing-*.desktop; do
  [[ -f "$d" ]] || continue
  line="$(grep -m1 '^Exec=' "$d" | cut -d= -f2-)"
  bin="$line"
  case "$line" in
    archricing-terminal-exec\ *) bin="$(echo "$line" | awk '{print $2}')" ;;
  esac
  first="$(echo "$bin" | awk '{print $1}')"
  if command -v "$first" >/dev/null 2>&1; then n_ok=$((n_ok+1)); else
    mv -f "$d" "$DISABLED/"; echo "menu: désactivé (binaire absent: $first): $(basename "$d")"; n_off=$((n_off+1))
  fi
done
echo "menu: $n_ok actives, $n_off désactivées (voir $DISABLED)"
