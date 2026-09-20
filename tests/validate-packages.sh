#!/usr/bin/env bash
# tests/validate-packages.sh — À LANCER SUR ARCH : vérifie chaque paquet officiel via pacman -Si.
# Les paquets AUR/BlackArch sont listés séparément et jamais bloquants.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v pacman >/dev/null || { echo "Non-Arch : skip (lancez tests/check-tree.sh)"; exit 0; }
fail=0
for f in packages/core/packages.txt packages/desktop/packages.txt packages/personalization/packages.txt; do
  while read -r p; do
    [[ "$p" =~ ^\s*(#|$) ]] && continue
    pacman -Si "$p" >/dev/null 2>&1 || { echo "INCONNU (officiel ?): $p [$f]"; fail=1; }
  done < "$ROOT/$f"
done
echo "--- AUR (informatif, non bloquant) ---"
grep -vE '^\s*(#|$)' "$ROOT/packages/aur/aur-packages.txt" | head -30
[[ $fail -eq 0 ]] && echo "PACKAGES OFFICIELS OK" || echo "Corrigez les paquets marqués INCONNU (voir docs/troubleshooting.md)."
