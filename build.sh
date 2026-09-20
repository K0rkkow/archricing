#!/usr/bin/env bash
# =============================================================================
# build.sh — OFFICIAL AND ONLY entry point for building the ArchRicing ISO.
#
#   git clone https://github.com/K0rkkow/archricing.git
#   cd archricing
#   ./build.sh
#
# Result: out/*.iso + out/SHA256SUMS + out/build.log
#
# - On Arch / Arch-based: builds natively with mkarchiso (asks once for sudo).
# - Anywhere else (Fedora, Debian, Ubuntu, ...): builds automatically inside
#   an archlinux:latest container (podman preferred, docker fallback).
# - The ISO is ALWAYS produced by archiso/mkarchiso in an Arch environment.
# - Internal hooks ARCHRICING_* are test-only (see tests/test-build.sh).
# =============================================================================
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEP="init"
IN_FAIL=0
FAIL_HINT=""

# --- internal/test hooks (never needed by end users) --------------------------
PROFILE_DIR="${ARCHRICING_PROFILE_DIR:-$ROOT_DIR/iso/profile}"
AIROOTFS_SRC="${ARCHRICING_AIROOTFS_SRC:-$ROOT_DIR/iso/airootfs}"
MKARCHISO_BIN="${ARCHRICING_MKARCHISO_BIN:-mkarchiso}"
PACMAN_BIN="${ARCHRICING_PACMAN_BIN:-pacman}"
ASSUME_ARCH="${ARCHRICING_ASSUME_ARCH:-0}"
NO_SUDO="${ARCHRICING_NO_SUDO:-0}"
IN_CONTAINER="${ARCHRICING_IN_CONTAINER:-0}"

OUT_DIR="$ROOT_DIR/out"
BUILD_DIR="$ROOT_DIR/.build"
WORK_DIR="$BUILD_DIR/work"
STAGE_PROFILE="$BUILD_DIR/profile"
LOG_FILE="$OUT_DIR/build.log"
CONTAINER_IMAGE="archlinux:latest"

MODE="native"
SUDO="sudo"

# --- output -------------------------------------------------------------------
step() { printf '[%s] %s\n' "$1" "$2"; }
info() { printf '[build] %s\n' "$*"; }

build_error() { # profile / usage errors: hard stop before mkarchiso
  IN_FAIL=1
  printf 'ARCHRICING BUILD ERROR\n----------------------\n%s\n' "$*" >&2
  exit 1
}

on_err() { # unexpected failures: full context banner, never a false success
  local rc=$1 line=$2 cmd=$3
  [[ "$IN_FAIL" -eq 1 ]] && exit "$rc"
  IN_FAIL=1
  printf '\n============================================\nARCHRICING ISO BUILD FAILED\n============================================\n\nStep:\n  %s\n\nCommand:\n  %s (line %s)\n\nExit code:\n  %s\n\nLog:\n  %s\n' \
    "$STEP" "$cmd" "$line" "$rc" "$LOG_FILE" >&2
  [[ -n "$FAIL_HINT" ]] && printf '\nHint:\n  %s\n' "$FAIL_HINT" >&2
  printf '\nSee:\n\n  %s\n' "$LOG_FILE" >&2
  exit "$rc"
}
trap 'on_err $? $LINENO "$BASH_COMMAND"' ERR

usage() {
  cat <<'EOF'
Usage: ./build.sh [--help] [--check-only] [--clean]

Builds the ArchRicing ISO into out/ (ISO + SHA256SUMS + build.log).
Works on Arch natively, or anywhere via an archlinux container.
EOF
}

# --- flags --------------------------------------------------------------------
CHECK_ONLY=0
CLEAN_ONLY=0
PRINT_ROOT=0
PRINT_PROFILE=0
for arg in "$@"; do
  case "$arg" in
    --help|-h) usage; exit 0 ;;
    --check-only) CHECK_ONLY=1 ;;
    --clean) CLEAN_ONLY=1 ;;
    --in-container) IN_CONTAINER=1 ;;
    --print-root) PRINT_ROOT=1 ;;
    --print-profile) PRINT_PROFILE=1 ;;
    *) build_error "unknown option: $arg (see ./build.sh --help)" ;;
  esac
done

if [[ "$PRINT_ROOT" -eq 1 ]]; then printf '%s\n' "$ROOT_DIR"; exit 0; fi
if [[ "$PRINT_PROFILE" -eq 1 ]]; then printf '%s\n' "$PROFILE_DIR"; exit 0; fi
if [[ "$CLEAN_ONLY" -eq 1 ]]; then
  rm -rf "$BUILD_DIR" "$ROOT_DIR/work" "$OUT_DIR"
  info "cleaned: .build/ work/ out/"
  exit 0
fi

# --- helpers ------------------------------------------------------------------
is_arch() {
  [[ "$ASSUME_ARCH" == "1" ]] && return 0
  [[ -f /etc/arch-release ]] && return 0
  command -v pacman >/dev/null 2>&1 || return 1
  grep -qi 'arch' /etc/os-release 2>/dev/null
}

need_cmd() { command -v "$1" >/dev/null 2>&1; }

# =============================================================================
# [1/8] project
# =============================================================================
STEP="[1/8] Checking project"
step "1/8" "Checking project..."
[[ -d "$ROOT_DIR/iso" && -d "$ROOT_DIR/packages" && -d "$ROOT_DIR/scripts" ]] \
  || build_error "project layout broken under $ROOT_DIR (expected iso/, packages/, scripts/)."

# =============================================================================
# [2/8] profile
# =============================================================================
STEP="[2/8] Checking profile"
step "2/8" "Checking profile..."
PROFILE_MISSING=()
[[ -d "$PROFILE_DIR" ]] || build_error "profile directory not found: $PROFILE_DIR"
for f in profiledef.sh packages.x86_64 pacman.conf bootstrap_packages.x86_64; do
  [[ -f "$PROFILE_DIR/$f" ]] || PROFILE_MISSING+=("$f")
done
[[ -d "$AIROOTFS_SRC" ]] || PROFILE_MISSING+=("airootfs/ (directory)")
if [[ "${#PROFILE_MISSING[@]}" -gt 0 ]]; then
  {
    echo "The Archiso profile is incomplete."
    echo ""
    echo "Missing:"
    for m in "${PROFILE_MISSING[@]}"; do echo "- $m"; done
  } >&2
  build_error "profile incomplete (${#PROFILE_MISSING[@]} entries missing — list above)."
fi
# pacman.conf actually referenced by profiledef?
if grep -qE '^pacman_conf=' "$PROFILE_DIR/profiledef.sh"; then
  ref="$(grep -E '^pacman_conf=' "$PROFILE_DIR/profiledef.sh" | cut -d= -f2 | tr -d "\"' ")"
  [[ -f "$PROFILE_DIR/$ref" ]] || build_error "profiledef.sh references pacman_conf=$ref but $PROFILE_DIR/$ref is missing."
fi
# bootloader config dirs (warn only: first real build will confirm)
for d in syslinux grub efiboot; do
  [[ -d "$PROFILE_DIR/$d" ]] || info "note: $d/ absent from profile (bootloader configs) — first real build will confirm."
done
info "profile OK: $PROFILE_DIR"

# =============================================================================
# [3/8] build environment (native Arch vs container)
# =============================================================================
STEP="[3/8] Checking build environment"
step "3/8" "Checking build environment..."
if [[ "$IN_CONTAINER" -eq 1 ]]; then
  MODE="container-inner"
  info "running INSIDE archlinux container."
elif is_arch; then
  MODE="native"
  info "Arch environment detected: native mkarchiso build."
else
  MODE="container"
  if need_cmd podman; then CRUN="podman"; elif need_cmd docker; then CRUN="docker"
  else
    build_error "not Arch (no pacman/arch-release) and neither podman nor docker found.
Install a container runtime, or build on Arch Linux / Arch-based."
  fi
  info "non-Arch host: will build inside archlinux:latest via $CRUN."
fi

# Container path: preflight done on host for steps 1-2; the container re-runs
# the FULL pipeline (all 8 steps) where Arch tooling exists.
if [[ "$MODE" == "container" ]]; then
  [[ "$CHECK_ONLY" -eq 1 ]] && { info "check-only: project+profile OK; $CRUN available for the real build."; exit 0; }
  info "pulling $CONTAINER_IMAGE ..."
  FAIL_HINT="container image pull failed — check network access and $CRUN setup."
  "$CRUN" pull "$CONTAINER_IMAGE" >/dev/null || build_error "$CRUN pull $CONTAINER_IMAGE failed."
  FAIL_HINT=""
  HOST_UID="$(id -u)"; HOST_GID="$(id -g)"
  FAIL_HINT="container build failed — see out/build.log (written inside the mounted repo)."
  "$CRUN" run --rm --privileged \
    -v "${ROOT_DIR}:/src:z" \
    -e "HOST_UID=$HOST_UID" -e "HOST_GID=$HOST_GID" \
    -e ARCHRICING_IN_CONTAINER=1 \
    "$CONTAINER_IMAGE" bash /src/build.sh "$@" \
    || build_error "container build failed (see out/build.log)."
  FAIL_HINT=""
  # ownership back to the invoking user (never leave everything root-owned)
  if [[ "$HOST_UID" -ne 0 ]]; then
    if need_cmd sudo; then sudo chown -R "$HOST_UID:$HOST_GID" "$OUT_DIR" "$BUILD_DIR" 2>/dev/null \
      || info "warning: could not chown outputs (sudo failed) — out/ may be root-owned."
    elif [[ "$(id -u)" -eq 0 ]]; then chown -R "$HOST_UID:$HOST_GID" "$OUT_DIR" "$BUILD_DIR"
    else info "warning: no sudo available — out/ may be root-owned."; fi
  fi
  ISO_CHK="$(ls -t "$OUT_DIR"/archricing-*.iso 2>/dev/null | head -n1 || true)"
  [[ -n "${ISO_CHK:-}" && -s "$OUT_DIR/SHA256SUMS" ]] || build_error "container finished but no ISO+SHA256SUMS in out/."
  info "container build outputs verified."
  exit 0
fi

# --- from here: native Arch or container-inner (Arch tooling present) ----------
if [[ "$EUID" -eq 0 ]]; then SUDO=""; fi
if [[ "$NO_SUDO" == "1" ]]; then SUDO=""; fi
run_priv() { if [[ -n "$SUDO" ]]; then sudo "$@"; else "$@"; fi; }

# =============================================================================
# [4/8] dependencies
# =============================================================================
STEP="[4/8] Checking dependencies"
step "4/8" "Checking dependencies..."
NEED_CMDS=("$MKARCHISO_BIN" mksquashfs xorriso python3 git sha256sum)
MISSING=()
for c in "${NEED_CMDS[@]}"; do need_cmd "$c" || MISSING+=("$c"); done
if [[ "$SUDO" == "sudo" ]] && ! need_cmd sudo; then MISSING+=("sudo"); fi
if [[ "${#MISSING[@]}" -gt 0 ]]; then
  info "missing commands: ${MISSING[*]}"
  [[ "$CHECK_ONLY" -eq 1 ]] && build_error "preflight: missing dependencies (${MISSING[*]})."
  if [[ ! -t 0 ]]; then
    build_error "missing dependencies (${MISSING[*]}) in non-interactive mode: install archiso first."
  fi
  printf 'Install required packages with pacman? [y/N] '
  read -r answer || answer=""
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    run_priv "$PACMAN_BIN" -Syu --needed --noconfirm archiso git python \
      || build_error "pacman installation of archiso failed."
    MISSING=()
    for c in "${NEED_CMDS[@]}"; do need_cmd "$c" || MISSING+=("$c"); done
    [[ "${#MISSING[@]}" -eq 0 ]] || build_error "still missing after install: ${MISSING[*]}."
  else
    build_error "missing dependencies (${MISSING[*]}): install them, then re-run ./build.sh."
  fi
fi
# an installed mkarchiso is not enough: the command must REALLY work
"$MKARCHISO_BIN" --help >/dev/null 2>&1 || "$MKARCHISO_BIN" -h >/dev/null 2>&1 \
  || build_error "mkarchiso is installed but does not run (try reinstalling archiso)."
MK_HELP="$("$MKARCHISO_BIN" --help 2>&1 || "$MKARCHISO_BIN" -h 2>&1 || true)"
echo "$MK_HELP" | grep -q '\-w' || build_error "this mkarchiso does not support -w (work dir): version incompatible."
echo "$MK_HELP" | grep -q '\-o' || build_error "this mkarchiso does not support -o (out dir): version incompatible."
RMWORK=()
echo "$MK_HELP" | grep -q '\-r' && RMWORK=(-r)
info "dependencies OK (mkarchiso functional)."

# =============================================================================
# [5/8] packages (DB validation BEFORE any long build + AUR separation)
# =============================================================================
STEP="[5/8] Checking packages"
step "5/8" "Checking packages..."
if [[ "$CHECK_ONLY" -eq 1 ]]; then
  info "check-only: structural package scan (no pacman DB query)."
else
  info "refreshing pacman databases..."
  FAIL_HINT="pacman database refresh failed — check network and mirrors."
  run_priv "$PACMAN_BIN" -Sy --noconfirm >/dev/null 2>&1 \
    || build_error "pacman -Sy failed (network or mirror issue)."
  FAIL_HINT=""
fi
# merged official set = profile list + project lists (Security suite stays an
# install-time Calamares choice: single ISO, edition applied at install)
MERGED="$BUILD_DIR/merged-packages.txt"
mkdir -p "$BUILD_DIR"
grep -h -vE '^\s*(#|$)' "$PROFILE_DIR/packages.x86_64" \
  "$ROOT_DIR"/packages/core/packages.txt \
  "$ROOT_DIR"/packages/desktop/packages.txt \
  "$ROOT_DIR"/packages/personalization/packages.txt 2>/dev/null | sort -u > "$MERGED"
[[ -s "$MERGED" ]] || build_error "merged package list is empty — profile and package lists unreadable."
# known AUR names (must never silently reach mkarchiso)
AUR_SET="$BUILD_DIR/aur-names.txt"
{ grep -h -vE '^\s*(#|$)' "$ROOT_DIR"/packages/aur/aur-packages.txt 2>/dev/null | awk '{print $1}';
  grep -h -vE '^\s*(#|$)' "$ROOT_DIR"/packages/security/security-aur.txt 2>/dev/null | cut -d'|' -f1 | tr -d ' \r';
} | sort -u > "$AUR_SET"
BAD_PKGS=()
if [[ "$CHECK_ONLY" -eq 0 ]]; then
  while read -r p; do
    [[ -z "$p" ]] && continue
    if "$PACMAN_BIN" -Si "$p" >/dev/null 2>&1; then continue; fi
    if grep -qxF "$p" "$AUR_SET" 2>/dev/null; then BAD_PKGS+=("$p (AUR — no local build mechanism, refusing to fake it)")
    else BAD_PKGS+=("$p"); fi
  done < "$MERGED"
  if [[ "${#BAD_PKGS[@]}" -gt 0 ]]; then
    msg="PACKAGE VALIDATION FAILED\n\nMissing packages:"
    for b in "${BAD_PKGS[@]}"; do msg="$msg\n- $b"; done
    # shellcheck disable=SC2059
    printf "$msg\n" > /dev/stderr
    build_error "package validation failed (${#BAD_PKGS[@]} missing — list above). Fix the lists, then re-run."
  fi
  info "packages OK ($(wc -l < "$MERGED" | tr -d ' ') official packages resolve)."
else
  # check-only: AUR-leak scan without DB
  while read -r p; do
    [[ -z "$p" ]] && continue
    if grep -qxF "$p" "$AUR_SET" 2>/dev/null; then BAD_PKGS+=("$p (AUR)"); fi
  done < "$MERGED"
  [[ "${#BAD_PKGS[@]}" -eq 0 ]] || build_error "AUR names would reach mkarchiso: ${BAD_PKGS[*]}"
  info "packages OK (structural AUR-leak scan)."
fi
# Calamares Security choice must mirror the official security list
while read -r p; do
  grep -q "      - $p$" "$ROOT_DIR/calamares/modules/packagechooser@edition.conf" \
    || build_error "edition divergence: $p (security-official.txt) missing from packagechooser@edition.conf"
done < <(grep -vE '^\s*(#|$)' "$ROOT_DIR/packages/security/security-official.txt")
info "editions in sync."

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  info "preflight OK (no changes made)."
  exit 0
fi

# sudo exactly once, now that everything checkable is green
if [[ -n "$SUDO" ]]; then
  info "requesting privileges once for the build phase..."
  sudo -v || build_error "cannot obtain sudo privileges."
fi

# =============================================================================
# [6/8] preparing build (assemble profile under .build/, never touch sources)
# =============================================================================
STEP="[6/8] Preparing build"
step "6/8" "Preparing build..."
mkdir -p "$OUT_DIR"
touch "$OUT_DIR/.writetest" 2>/dev/null || build_error "out/ is not writable."
rm -f "$OUT_DIR/.writetest"
FREE_KB="$(df -k "$ROOT_DIR" | awk 'NR==2 {print $4}')"
[[ "${FREE_KB:-0}" -ge 8388608 ]] || build_error "only $((FREE_KB / 1024 / 1021024)) MB free under $ROOT_DIR — need at least 8 GB."
[[ "${FREE_KB:-0}" -ge 20971520 ]] || info "warning: less than 20 GB free — build may still succeed."
if need_cmd curl; then
  curl --max-time 10 -sI https://archlinux.org >/dev/null 2>&1 \
    || info "warning: archlinux.org unreachable from here (pacman -Sy will confirm)."
elif need_cmd getent; then
  getent hosts archlinux.org >/dev/null 2>&1 \
    || info "warning: DNS looks broken (pacman -Sy will confirm)."
fi
rm -rf "$WORK_DIR" "$STAGE_PROFILE"
mkdir -p "$WORK_DIR" "$STAGE_PROFILE"
info "staging profile (sources untouched)..."
cp -a "$PROFILE_DIR/." "$STAGE_PROFILE/"
cp -a "$AIROOTFS_SRC" "$STAGE_PROFILE/airootfs"
# merge project package lists into the STAGED copy only
while read -r p; do grep -qxF "$p" "$STAGE_PROFILE/packages.x86_64" || echo "$p" >> "$STAGE_PROFILE/packages.x86_64"; done < "$MERGED"
sort -u "$STAGE_PROFILE/packages.x86_64" -o "$STAGE_PROFILE/packages.x86_64"
# regenerate derived assets (idempotent generators)
python3 "$ROOT_DIR/packages/security/menu/generate-menu.py"
python3 "$ROOT_DIR/configs/kde/generate-variants.py"
# assets into staged airootfs
AIR="$STAGE_PROFILE/airootfs"
rm -rf "$AIR/usr/share/archricing"; mkdir -p "$AIR/usr/share/archricing"
cp -a "$ROOT_DIR/configs" "$AIR/usr/share/archricing/"
cp -a "$ROOT_DIR/wallpapers" "$AIR/usr/share/archricing/"
for d in "$ROOT_DIR"/themes/*/; do
  t="$(basename "$d")"; mkdir -p "$AIR/usr/share/archricing/themes/$t"
  cp -a "$d/theme.json" "$AIR/usr/share/archricing/themes/$t/"
done
cp -a "$ROOT_DIR/apps" "$AIR/usr/share/archricing/"
cp -a "$ROOT_DIR/calamares" "$AIR/usr/share/archricing/"
cp -a "$ROOT_DIR/packages" "$AIR/usr/share/archricing/"
echo "2026.09-dev" > "$AIR/usr/share/archricing/VERSION"
rm -rf "$AIR/etc/calamares"
mkdir -p "$AIR/etc/calamares/modules" "$AIR/etc/calamares/branding"
cp -a "$ROOT_DIR/calamares/settings/settings.conf" "$AIR/etc/calamares/settings.conf"
cp -a "$ROOT_DIR"/calamares/modules/*.conf "$AIR/etc/calamares/modules/"
cp -a "$ROOT_DIR/calamares/branding/archricing" "$AIR/etc/calamares/branding/"
MODLIB="$AIR/usr/lib/calamares/modules/archricing_experience"
rm -rf "$MODLIB"; mkdir -p "$MODLIB"
cp -a "$ROOT_DIR/calamares/custom-modules/archricing_experience/module.desc" "$MODLIB/"
cp -a "$ROOT_DIR/calamares/custom-modules/archricing_experience/main.py" "$MODLIB/"
install -Dm644 "$ROOT_DIR/configs/zsh/.zshrc" "$AIR/etc/skel/.zshrc"
# GUI launchers required by profiledef file_permissions (created here so the
# permission step never points at missing files)
printf '#!/usr/bin/env bash\nexec python3 /usr/share/archricing/apps/settings/app.py "$@"\n' > "$AIR/usr/local/bin/archricing-settings"
printf '#!/usr/bin/env bash\nexec python3 /usr/share/archricing/apps/welcome/app.py "$@"\n' > "$AIR/usr/local/bin/archricing-welcome"
chmod +x "$AIR/root/customize_airootfs.sh" \
  "$AIR/usr/local/bin/archricing" "$AIR/usr/local/bin/archricing-postinstall" \
  "$AIR/usr/local/bin/archricing-settings" "$AIR/usr/local/bin/archricing-welcome"
touch "$BUILD_DIR/start.marker"
info "staging complete."

# =============================================================================
# [7/8] building ISO (the ONLY mkarchiso call; profile dir is last argument)
# =============================================================================
STEP="[7/8] Building ISO"
step "7/8" "Building ISO..."
{
  echo "== ArchRicing build log =="
  echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "host: $(uname -smr) | arch: $(uname -m)"
  echo "mkarchiso: $($MKARCHISO_BIN --version 2>&1 | head -n1 || echo unknown)"
  echo "profile: $PROFILE_DIR"
  echo "mode: $MODE"
  echo "start: $(date +%s)"
} > "$LOG_FILE"
FAIL_HINT="mkarchiso failed — inspect the log tail above and out/build.log (disk space, mirrors, profile)."
set +e
run_priv "$MKARCHISO_BIN" -v "${RMWORK[@]}" -w "$WORK_DIR" -o "$OUT_DIR" "$STAGE_PROFILE" 2>&1 | tee -a "$LOG_FILE"
RC=${PIPESTATUS[0]}
set -e
echo "mkarchiso exit: $RC" | tee -a "$LOG_FILE"
[[ "$RC" -eq 0 ]] || build_error "mkarchiso exited with code $RC (see out/build.log)."

# =============================================================================
# [8/8] verifying ISO (no success message without a REAL, fresh ISO)
# =============================================================================
STEP="[8/8] Verifying ISO"
step "8/8" "Verifying ISO..."
CANDIDATES=()
for iso in "$OUT_DIR"/archricing-*.iso; do
  [[ -f "$iso" ]] || continue
  [[ "$iso" -nt "$BUILD_DIR/start.marker" ]] && CANDIDATES+=("$iso")
done
[[ "${#CANDIDATES[@]}" -gt 0 ]] || build_error "no ISO produced by this build in out/ (nothing newer than build start)."
ISO="$(ls -t "${CANDIDATES[@]}" | head -n1)"
[[ -s "$ISO" && -r "$ISO" ]] || build_error "$ISO is empty or unreadable."
python3 - "$ISO" <<'EOF' || build_error "$ISO does not look like an ISO image (no CD001 magic)."
import sys
with open(sys.argv[1], "rb") as f:
    f.seek(0x8001)
    assert f.read(5) == b"CD001", "no ISO9660 magic"
EOF
( cd "$OUT_DIR" && sha256sum "$(basename "$ISO")" > SHA256SUMS )
[[ -s "$OUT_DIR/SHA256SUMS" ]] || build_error "SHA256SUMS generation failed."
SIZE="$(du -h "$ISO" | cut -f1)"
# ownership back to the invoking user (never leave everything root-owned)
OWNER="${SUDO_USER:-}"; [[ -z "$OWNER" && -n "${HOST_UID:-}" ]] && OWNER="$HOST_UID"
if [[ -n "${OWNER:-}" && "$OWNER" != "0" && "$(id -u)" -eq 0 ]]; then
  chown -R "$OWNER" "$OUT_DIR" "$BUILD_DIR" 2>/dev/null || info "warning: chown of outputs failed."
fi
echo "result: SUCCESS size=$SIZE iso=$(basename "$ISO")" >> "$LOG_FILE"

cat <<EOF

============================================
ARCHRICING ISO BUILD SUCCESSFUL
============================================

ISO:
  out/$(basename "$ISO")

SHA256:
  out/SHA256SUMS

Size:
  $SIZE

Build log:
  out/build.log

You can now boot the ISO in a VM or write it
to a USB using an appropriate imaging tool.
EOF
