#!/usr/bin/env bash
# build.sh — POINT D'ENTRÉE UNIQUE ET OFFICIEL du build ISO ArchRicing.
#
#   git clone https://github.com/K0rkkow/archricing.git
#   cd archricing
#   ./build.sh
#
# Tout le reste est automatique : compatibilité, dépendances (avec proposition
# d'installation via pacman sur Arch), fichiers requis, permissions, préparation,
# build archiso privilégié, vérification ISO + SHA256SUMS.
# Les scripts de scripts/ sont des détails d'implémentation internes.
#
# Options :
#   --help        aide
#   --check-only  pré-vol uniquement (aucune modification, aucun sudo, aucun build)
#   --clean       nettoie work/ et out/ puis quitte (délègue à scripts/clean-build.sh)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEP="init"

fail() { printf 'ERREUR [étape : %s]\n%s\n' "$STEP" "$*" >&2; exit 1; }
info() { printf '[build] %s\n' "$*"; }

usage() {
  cat <<'EOF'
Usage: ./build.sh [--help] [--check-only] [--clean]

Construit l'ISO ArchRicing (out/archricing-YYYY.MM.DD-x86_64.iso + out/SHA256SUMS).
À lancer depuis la racine du dépôt, sur Arch Linux / Arch-based avec pacman.
Les dépendances manquantes (archiso, ...) sont proposées à l'installation.
EOF
}

CLEAN_ONLY=0; CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --help|-h) usage; exit 0 ;;
    --check-only) CHECK_ONLY=1 ;;
    --clean) CLEAN_ONLY=1 ;;
    *) fail "option inconnue : $arg (voir ./build.sh --help)" ;;
  esac
done

if [[ "$CLEAN_ONLY" -eq 1 ]]; then
  bash "$ROOT/scripts/clean-build.sh"
  exit 0
fi

# ---- 1+2. Compatibilité + archiso ------------------------------------------------
STEP="compat"
if ! command -v pacman >/dev/null 2>&1; then
  fail "pacman introuvable : le build ISO exige Arch Linux / Arch-based (voir docs/build-windows.md)."
fi
if [[ ! -f /etc/arch-release ]] && ! grep -qi 'arch' /etc/os-release 2>/dev/null; then
  info "AVERTISSEMENT : distribution non reconnue comme Arch-based — tentative quand même."
fi

# ---- 3+4. Dépendances (détection AVANT tout build) --------------------------------
STEP="deps"
NEED_CMDS=(mkarchiso mksquashfs xorriso python3 git sudo)
MISSING=()
for c in "${NEED_CMDS[@]}"; do command -v "$c" >/dev/null 2>&1 || MISSING+=("$c"); done
if [[ "${#MISSING[@]}" -gt 0 ]]; then
  info "Commandes manquantes : ${MISSING[*]}"
  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    fail "pré-vol : dépendances manquantes (${MISSING[*]})."
  fi
  if [[ ! -t 0 ]]; then
    fail "dépendances manquantes (${MISSING[*]}) et mode non interactif : installez-les (sudo pacman -S --needed archiso git python sudo)."
  fi
  printf 'Installer automatiquement les paquets requis avec pacman ? [o/N] '
  read -r answer || answer=""
  if [[ "$answer" == "o" || "$answer" == "O" ]]; then
    sudo pacman -Syu --needed --noconfirm archiso git python sudo \
      || fail "l'installation des dépendances a échoué."
    MISSING=()
    for c in "${NEED_CMDS[@]}"; do command -v "$c" >/dev/null 2>&1 || MISSING+=("$c"); done
    [[ "${#MISSING[@]}" -eq 0 ]] || fail "toujours manquant après installation : ${MISSING[*]}."
  else
    fail "dépendances manquantes (${MISSING[*]}) : installez-les puis relancez ./build.sh."
  fi
fi
info "dépendances OK."

# ---- 5. Fichiers requis ------------------------------------------------------------
STEP="files"
NEED_FILES=(iso/profile/profiledef.sh iso/profile/packages.x86_64 iso/profile/pacman.conf
  iso/profile/bootstrap_packages.x86_64 iso/build.sh
  iso/airootfs/root/customize_airootfs.sh
  calamares/settings/settings.conf
  packages/core/packages.txt packages/desktop/packages.txt
  packages/security/security-official.txt
  scripts/build-iso.sh)
for f in "${NEED_FILES[@]}"; do
  [[ -f "$ROOT/$f" ]] || fail "fichier requis manquant : $f (dépôt incomplet ?)."
done
info "fichiers requis OK."

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  info "pré-vol OK (aucune modification effectuée)."
  exit 0
fi

# ---- 6. Permissions (sudo demandé une seule fois, ici) ------------------------------
STEP="perms"
[[ -r "$ROOT/iso/profile/profiledef.sh" && -w "$ROOT" ]] \
  || fail "permissions insuffisantes sur $ROOT (lecture/écriture requises)."
command -v sudo >/dev/null || fail "sudo introuvable (requis pour la phase archiso)."
info "élévation des privilèges pour la phase de build (une seule demande)…"
sudo -v || fail "impossible d'obtenir les privilèges sudo."

# ---- 7+8. Préparation + nettoyage temporaires ----------------------------------------
STEP="prepare"
mkdir -p "$ROOT/out"
if [[ -d "$ROOT/work" ]]; then
  info "nettoyage de l'ancien dossier temporaire work/…"
  rm -rf "$ROOT/work"
fi

# ---- 9. Build (phase privilégiée, appel interne unique) -------------------------------
STEP="build"
if ! sudo bash "$ROOT/scripts/build-iso.sh"; then
  fail "la phase archiso a échoué (voir le journal ci-dessus)."
fi

# ---- 10+11+12. Vérification réelle + résultat ------------------------------------------
STEP="verify"
ISO="$(ls -t "$ROOT"/out/archricing-*.iso 2>/dev/null | head -n1 || true)"
if [[ -z "${ISO:-}" || ! -f "$ISO" ]]; then
  fail "aucune ISO produite dans out/ (le build n'a rien généré)."
fi
if [[ ! -s "$ROOT/out/SHA256SUMS" ]]; then
  fail "SHA256SUMS manquant ou vide dans out/."
fi

cat <<EOF

ArchRicing ISO successfully built!

ISO:
${ISO#$ROOT/}

SHA256:
out/SHA256SUMS

Prochaines étapes : tester avec ./tests/test-qemu.sh uefi (voir docs/installation.md).
EOF
