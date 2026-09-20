#!/usr/bin/env bash
# iso/build.sh — appelé par scripts/build-iso.sh (point d'entrée officiel).
# Ne mute JAMAIS les sources : le profil est copié vers un répertoire temporaire,
# la fusion des paquets se fait sur la copie, puis mkarchiso tourne dessus.
# Pré-vol : dépendances + cohérence paquets/éditions/menu avant tout build.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"   # iso/ -> racine repo (layout fixe)
OUT="$ROOT/out" WORK="$ROOT/work" TMP_PROFILE="$WORK/profile"
fail=0

# ---- 0. Pré-vol -------------------------------------------------------------
for cmd in mkarchiso pacman mksquashfs xorriso; do
  command -v "$cmd" >/dev/null || { echo "MANQUANT: $cmd (sudo pacman -S archiso)" >&2; fail=1; }
done
[[ -f "$HERE/profile/pacman.conf" && -f "$HERE/profile/bootstrap_packages.x86_64" ]] \
  || { echo "MANQUANT: pacman.conf/bootstrap_packages.x86_64" >&2; fail=1; }
# Paquets interdits (inexistants) dans les listes officielles :
if grep -h -vE '^\s*(#|$)' "$ROOT"/packages/core/packages.txt "$ROOT"/packages/desktop/packages.txt \
    "$ROOT"/packages/personalization/packages.txt "$ROOT"/packages/security/security-official.txt \
    "$HERE/profile/packages.x86_64" | grep -qxE 'calamares-configs|ttf-font-nerd|qcoro-qt6|wallpapers|^p7zip$'; then
  echo "PAQUET INVALIDE détecté (voir docs/troubleshooting.md)" >&2; fail=1
fi
# L'édition SECURITY de Calamares doit refléter security-official.txt :
while read -r p; do
  grep -q "      - $p$" "$ROOT/calamares/modules/packagechooser@edition.conf" \
    || { echo "DIVERGENCE: $p absent de packagechooser@edition.conf" >&2; fail=1; }
done < <(grep -vE '^\s*(#|$)' "$ROOT/packages/security/security-official.txt")
[[ $fail -ne 0 ]] && { echo "PRÉ-VOL ÉCHOUÉ — build annulé" >&2; exit 1; }
echo "pré-vol OK"

command -v mkarchiso >/dev/null || { echo "ERREUR: archiso non installé (sudo pacman -S archiso)" >&2; exit 1; }
[[ $EUID -eq 0 ]] || { echo "ERREUR: lancer en root (sudo ./scripts/build-iso.sh)" >&2; exit 1; }
[[ -d "$ROOT/packages" && -d "$HERE/profile" ]] || { echo "ERREUR: layout inattendu (ROOT=$ROOT)" >&2; exit 1; }

rm -rf "$WORK"
mkdir -p "$OUT" "$TMP_PROFILE"

# 1. Profil -> copie de travail
cp -a "$HERE/profile/." "$TMP_PROFILE/"

# 2. Fusion paquets (core + desktop + personalization, sans doublons/commentaires)
#    NOTE : la suite Security officielle n'est PAS dans le live (choix Calamares).
grep -h -vE '^\s*(#|$)' "$ROOT"/packages/core/packages.txt \
  "$ROOT"/packages/desktop/packages.txt \
  "$ROOT"/packages/personalization/packages.txt | sort -u > "$WORK/extra-pkgs.txt"
while read -r p; do grep -qxF "$p" "$TMP_PROFILE/packages.x86_64" || echo "$p" >> "$TMP_PROFILE/packages.x86_64"; done < "$WORK/extra-pkgs.txt"
sort -u "$TMP_PROFILE/packages.x86_64" -o "$TMP_PROFILE/packages.x86_64"

# 3. Générateurs (menu Security + variantes Plasma) — idempotents
python3 "$ROOT/packages/security/menu/generate-menu.py"
python3 "$ROOT/configs/kde/generate-variants.py"

# 4. Assets ArchRicing -> airootfs/usr/share/archricing (utilisé par customize_airootfs.sh
#    en live ET par archricing-postinstall sur la cible, via unpackfs)
ASSETS="$HERE/airootfs/usr/share/archricing"
rm -rf "$ASSETS"
mkdir -p "$ASSETS"
cp -a "$ROOT/configs" "$ASSETS/"
cp -a "$ROOT/wallpapers" "$ASSETS/"
for d in "$ROOT"/themes/*/; do
  t="$(basename "$d")"
  mkdir -p "$ASSETS/themes/$t"
  cp -a "$d/theme.json" "$ASSETS/themes/$t/"
done
cp -a "$ROOT/apps" "$ASSETS/"
cp -a "$ROOT/calamares" "$ASSETS/"
cp -a "$ROOT/packages" "$ASSETS/"
cp -a "$ROOT/scripts/archricing" "$ASSETS/scripts/" 2>/dev/null || true
echo "2026.09-dev" > "$ASSETS/VERSION"

# 5. Calamares live : /etc/calamares/{settings.conf,modules,branding}
rm -rf "$HERE/airootfs/etc/calamares"
mkdir -p "$HERE/airootfs/etc/calamares/modules" "$HERE/airootfs/etc/calamares/branding"
cp -a "$ROOT/calamares/settings/settings.conf" "$HERE/airootfs/etc/calamares/settings.conf"
cp -a "$ROOT"/calamares/modules/*.conf "$HERE/airootfs/etc/calamares/modules/"
cp -a "$ROOT/calamares/branding/archricing" "$HERE/airootfs/etc/calamares/branding/"

# 6. Module Calamares personnalisé (viewmodule+job PythonQt)
MODLIB="$HERE/airootfs/usr/lib/calamares/modules/archricing_experience"
rm -rf "$MODLIB"; mkdir -p "$MODLIB"
cp -a "$ROOT/calamares/custom-modules/archricing_experience/module.desc" "$MODLIB/"
cp -a "$ROOT/calamares/custom-modules/archricing_experience/main.py" "$MODLIB/"

# 7. skel synchronisé depuis configs/ (source unique de vérité)
install -Dm644 "$ROOT/configs/zsh/.zshrc" "$HERE/airootfs/etc/skel/.zshrc"

# 8. Bits exécutables (perdus si édition sous Windows)
chmod +x "$HERE/airootfs/root/customize_airootfs.sh" \
         "$HERE/airootfs/usr/local/bin/archricing" \
         "$HERE/airootfs/usr/local/bin/archricing-postinstall" 2>/dev/null || true

# 9. Build
mkarchiso -v -w "$WORK/mkarchiso" -o "$OUT" "$TMP_PROFILE"
ISO="$(ls -t "$OUT"/archricing-*.iso | head -n1)"
( cd "$OUT" && sha256sum "$(basename "$ISO")" > SHA256SUMS )
echo "OK: $ISO"
cat "$OUT/SHA256SUMS"
