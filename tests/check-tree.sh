#!/usr/bin/env bash
# tests/check-tree.sh — contrôle statique PORTABLE (bash + grep + python3 uniquement).
# Tourne sous Linux, Git Bash, MSYS2 et WSL. Ne teste RIEN qui exige Arch/Linux :
# pas de pacman, pas de mkarchiso, pas de QEMU, pas de Plasma (voir BUILD_STATUS.md).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
need=(README.md LICENSE CONTRIBUTING.md .gitattributes .gitignore
 iso/profile/profiledef.sh iso/profile/packages.x86_64 iso/profile/pacman.conf iso/profile/bootstrap_packages.x86_64
 iso/build.sh iso/clean.sh
 iso/airootfs/root/customize_airootfs.sh iso/airootfs/usr/local/bin/archricing iso/airootfs/usr/local/bin/archricing-postinstall
 iso/airootfs/usr/share/applications/archricing-install.desktop iso/airootfs/etc/sddm.conf.d/archricing.conf
 packages/core/packages.txt packages/desktop/packages.txt packages/personalization/packages.txt
 packages/security/security-packages.txt packages/security/security-official.txt packages/security/security-aur.txt
 packages/security/menu/security-tools.json packages/security/menu/generate-menu.py
 packages/editions/README.md
 configs/kde/kwinrc configs/kde/generate-variants.py configs/install-profile.default.conf
 configs/kitty/kitty.conf configs/fastfetch/config.jsonc configs/zsh/.zshrc configs/starship/starship.toml configs/sddm/sddm.conf
 configs/systemd/archricing-security-aur.service
 scripts/build-iso.sh scripts/clean-build.sh scripts/post-install.sh scripts/install.sh
 scripts/hardware-detect.sh scripts/diagnostics.sh scripts/reset.sh scripts/archricing
 scripts/archricing-terminal-exec scripts/validate-menu.sh scripts/install-security-aur.sh
 calamares/settings/settings.conf calamares/branding/archricing/branding.desc
 calamares/modules/packages.conf calamares/modules/shellprocess@archricing-postinstall.conf
 calamares/modules/packagechooser@edition.conf calamares/modules/displaymanager.conf
 calamares/modules/unpackfs.conf calamares/modules/services-systemd.conf
 calamares/custom-modules/archricing_experience/module.desc calamares/custom-modules/archricing_experience/main.py
 docs/BUILD_STATUS.md docs/editions.md docs/build-windows.md)
for f in "${need[@]}"; do [[ -f "$ROOT/$f" ]] || { echo "MANQUANT: $f"; fail=1; }; done
if [[ -f "$ROOT/calamares/modules/shellprocess-archricing-postinstall.conf" ]]; then echo "OBSOLETE: shellprocess-archricing-postinstall.conf (utiliser shellprocess@...)"; fail=1; fi
bash -n "$ROOT"/scripts/*.sh "$ROOT"/scripts/archricing "$ROOT"/scripts/archricing-terminal-exec "$ROOT"/iso/*.sh "$ROOT"/tests/*.sh "$ROOT"/iso/airootfs/root/customize_airootfs.sh && echo "bash -n OK"
python3 -m py_compile "$ROOT"/apps/*/*.py "$ROOT"/calamares/custom-modules/archricing_experience/main.py "$ROOT"/packages/security/menu/generate-menu.py "$ROOT"/configs/kde/generate-variants.py && echo "python OK"
grep -q wobblywindowsEnabled "$ROOT/configs/kde/kwinrc" && echo "wobbly OK" || { echo "wobbly MANQUANT"; fail=1; }
grep -qi tileEnabled=false "$ROOT/configs/kde/kwinrc" && echo "no-tiling OK" || { echo "no-tiling MANQUANT"; fail=1; }
grep -q '^Placement=' "$ROOT/configs/kde/kwinrc" && echo "placement OK" || { echo "placement MANQUANT (clé Placement=)"; fail=1; }
grep -q background_opacity "$ROOT/configs/kitty/kitty.conf" && echo "kitty transparency OK" || { echo "kitty KO"; fail=1; }
grep -q pacman.conf "$ROOT/iso/profile/profiledef.sh" && echo "pacman.conf ref OK" || { echo "pacman.conf NON REFERENCE"; fail=1; }
for bad in "calamares-configs" "ttf-font-nerd" "qcoro-qt6" "^wallpapers$" "^p7zip$"; do
  if grep -RqE "$bad" "$ROOT"/packages/core/packages.txt "$ROOT"/packages/desktop/packages.txt "$ROOT"/packages/personalization/packages.txt "$ROOT"/packages/security/security-official.txt "$ROOT"/iso/profile/packages.x86_64; then echo "PAQUET INVALIDE: $bad"; fail=1; fi
done
echo "bad-packages scan OK"
# Éditions : packagechooser SECURITY == security-official.txt
while read -r p; do
  grep -q "      - $p$" "$ROOT/calamares/modules/packagechooser@edition.conf" || { echo "DIVERGENCE édition: $p"; fail=1; }
done < <(grep -vE '^\s*(#|$)' "$ROOT/packages/security/security-official.txt")
echo "editions sync OK"
# Menu : JSON valide + générés présents + chaque pkg dans official/aur
python3 - "$ROOT" <<'EOF'
import json, sys, glob, os
root = sys.argv[1]
data = json.load(open(root + "/packages/security/menu/security-tools.json"))
official = set(l.split()[0] for l in open(root + "/packages/security/security-official.txt") if l.strip() and not l.startswith("#"))
aur = set(l.split("|")[0].strip() for l in open(root + "/packages/security/security-aur.txt") if l.strip() and not l.startswith("#") and "|" in l)
n = 0
for t in data["tools"]:
    assert t["pkg"] in official or t["pkg"] in aur, "pkg inconnu: %s" % t["pkg"]
    assert os.path.isfile(root + "/packages/security/menu/applications/archricing-%s.desktop" % t["id"]), "desktop manquant: %s" % t["id"]
    n += 1
assert len(glob.glob(root + "/packages/security/menu/directories/*.directory")) == len(data["categories"]) + 1
assert len(glob.glob(root + "/configs/kde/variants/plasma-*.conf")) == 6
print("menu OK (%d outils)" % n)
EOF
[[ $? -eq 0 ]] || fail=1
# Profil : clés du .conf défaut == clés du module Calamares
for k in EDITION THEME WALLPAPER DOCK TOP_PANEL TRANSPARENCY BLUR ANIMATIONS WOBBLY ROUNDED ICONS CURSOR TERMINAL FASTFETCH SHELL STARSHIP WELCOME SETTINGS_APP SOFTWARE_APP UPDATE_APP; do
  grep -q "^$k=" "$ROOT/configs/install-profile.default.conf" || { echo "PROFIL: clé manquante $k"; fail=1; }
done
echo "profile keys OK"
[[ $fail -eq 0 ]] && echo "ALL CHECKS PASSED" || { echo "ECHECS détectés"; exit 1; }
