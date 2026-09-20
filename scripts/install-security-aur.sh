#!/usr/bin/env bash
# scripts/install-security-aur.sh — installe les paquets AUR Security (édition SECURITY).
# Lancé UNE fois au 1er boot via archricing-security-aur.service (User=installé).
# Jamais fatal : paquet introuvable/échec build = journalisé + ignoré.
# Usage manuel : ./scripts/install-security-aur.sh
set -uo pipefail
LIST_CANDIDATES=("/usr/share/archricing/packages/security/security-aur.txt" "$(dirname "$0")/../packages/security/security-aur.txt")
LIST=""
for c in "${LIST_CANDIDATES[@]}"; do [[ -f "$c" ]] && LIST="$c" && break; done
[[ -n "$LIST" ]] || { echo "liste AUR introuvable" >&2; exit 1; }
LOG="$HOME/.local/share/archricing/security-aur.log"
mkdir -p "$(dirname "$LOG")"

# Helper yay (bootstrap si absent)
if ! command -v yay >/dev/null 2>&1; then
  echo "bootstrap yay…" | tee -a "$LOG"
  tmp="$(mktemp -d)"; git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" >>"$LOG" 2>&1 \
    && (cd "$tmp/yay-bin" && makepkg -si --noconfirm >>"$LOG" 2>&1) || echo "WARN: yay bootstrap impossible (voir $LOG)"
  rm -rf "$tmp"
fi
command -v yay >/dev/null 2>&1 || { echo "ABANDON: pas de helper AUR (voir $LOG)"; exit 0; }

grep -vE '^\s*(#|$)' "$LIST" | while IFS='|' read -r pkg rest; do
  pkg="$(echo "$pkg" | tr -d ' \r')"
  [[ -z "$pkg" || "$pkg" == wpscan-ignored ]] && continue
  echo "== $pkg" | tee -a "$LOG"
  if yay -Si "$pkg" >>"$LOG" 2>&1; then
    yay -S --needed --noconfirm "$pkg" >>"$LOG" 2>&1 && echo "OK: $pkg" | tee -a "$LOG" || echo "FAIL(build): $pkg (voir $LOG)" | tee -a "$LOG"
  else
    echo "SKIP(introuvable): $pkg (voir fallback dans security-aur.txt)" | tee -a "$LOG"
  fi
done
echo "Terminé. Détail : $LOG"
