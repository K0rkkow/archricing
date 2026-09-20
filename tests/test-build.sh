#!/usr/bin/env bash
# tests/test-build.sh — tests for build.sh. Portable (bash + python3 only).
# Uses internal test hooks (ARCHRICING_*) with FAKE mkarchiso/pacman so the
# whole pipeline is REALLY exercised without Arch: assembly, package
# validation, AUR separation, failure banners, ISO verify, SHA256SUMS.
# Real build: only on Arch or with podman/docker (./build.sh directly).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAILN=0
ok() { PASS=$((PASS+1)); echo "ok: $*"; }
ko() { FAILN=$((FAILN+1)); echo "FAIL: $*"; }

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

# --- fakes --------------------------------------------------------------------
cat > "$T/mkarchiso-fake" <<'EOF'
#!/usr/bin/env bash
# fake mkarchiso: parses -o OUT + PROFILE(last arg), writes ISO with CD001 magic
OUT=""; PROFILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) OUT="$2"; shift 2 ;;
    -w) shift 2 ;;
    -v|-r) shift ;;
    --help|-h) echo "Usage: mkarchiso [-v] [-r] [-w dir] [-o dir] profile"; exit 0 ;;
    --version) echo "mkarchiso fake-1"; exit 0 ;;
    *) PROFILE="$1"; shift ;;
  esac
done
[[ -d "$PROFILE" && -f "$PROFILE/profiledef.sh" ]] || { echo "fake: bad profile"; exit 1; }
mkdir -p "$OUT"
ISO="$OUT/archricing-fake-$(date +%s).iso"
python3 - "$ISO" <<'PYEOF'
import sys
with open(sys.argv[1], "wb") as f:
    f.write(b"FAKEISO" + b"\0" * (0x8001 - 7) + b"CD001")
PYEOF
echo "fake mkarchiso wrote $ISO"
EOF
chmod +x "$T/mkarchiso-fake"
cat > "$T/pacman-stub" <<'EOF'
#!/usr/bin/env bash
# stub pacman: -Si fails only for $FAKE_PACMAN_MISSING entries; -Sy/-S* succeed
if [[ "${1:-}" == "-Si" ]]; then
  for bad in ${FAKE_PACMAN_MISSING:-}; do [[ "${2:-}" == "$bad" ]] && exit 1; done
  exit 0
fi
exit 0
EOF
chmod +x "$T/pacman-stub"
cat > "$T/mkarchiso-probe-ok-fail-run" <<'EOF'
#!/usr/bin/env bash
# passes --help/--version probes, fails the real invocation
case "${1:-}" in
  --help|-h) echo "Usage: mkarchiso [-v] [-r] [-w dir] [-o dir] profile"; exit 0 ;;
  --version) echo "mkarchiso fake-1"; exit 0 ;;
esac
echo "fake mkarchiso: boom"; exit 1
EOF
chmod +x "$T/mkarchiso-probe-ok-fail-run"
# stub remaining host tools missing outside Arch (mksquashfs/xorriso)
mkdir -p "$T/stubs"
for c in mksquashfs xorriso; do printf '#!/usr/bin/env bash\nexit 0\n' > "$T/stubs/$c"; chmod +x "$T/stubs/$c"; done
export PATH="$T/stubs:$PATH"

# --- 1. exists + executable + syntax -------------------------------------------
[[ -f "$ROOT/build.sh" ]] && ok "build.sh exists" || ko "build.sh exists"
bash -n "$ROOT/build.sh" && ok "bash -n" || ko "bash -n"
if [[ -d "$ROOT/.git" ]]; then
  git -C "$ROOT" ls-files -s build.sh | grep -q '^100755' && ok "executable bit" || ko "executable bit"
fi

# --- 2. ROOT_DIR from another cwd ----------------------------------------------
GOT="$(cd /tmp && bash "$ROOT/build.sh" --print-root)"
[[ "$GOT" == "$ROOT" ]] && ok "ROOT_DIR cwd-independent" || ko "ROOT_DIR cwd-independent (got $GOT)"

# --- 3. profile default ----------------------------------------------------------
GOT="$(bash "$ROOT/build.sh" --print-profile)"
[[ "$GOT" == "$ROOT/iso/profile" ]] && ok "profile default" || ko "profile default (got $GOT)"

# --- 4. missing profile -> ARCHRICING BUILD ERROR ---------------------------------
OUT4="$(ARCHRICING_PROFILE_DIR=/nonexistent-xyz bash "$ROOT/build.sh" --check-only 2>&1)"; RC=$?
[[ $RC -ne 0 && "$OUT4" == *"ARCHRICING BUILD ERROR"* && "$OUT4" != *"SUCCESSFUL"* ]] \
  && ok "missing profile clean error" || ko "missing profile clean error (rc=$RC)"

# --- 5. incomplete profile lists what is missing ----------------------------------
mkdir -p "$T/prof"; cp "$ROOT/iso/profile/profiledef.sh" "$T/prof/"
OUT5="$(ARCHRICING_PROFILE_DIR="$T/prof" bash "$ROOT/build.sh" --check-only 2>&1)"; RC=$?
[[ $RC -ne 0 && "$OUT5" == *"Missing:"* && "$OUT5" == *"packages.x86_64"* ]] \
  && ok "incomplete profile lists missing" || ko "incomplete profile lists missing (rc=$RC)"

# --- 6. missing mkarchiso -> clean error, no success ------------------------------
OUT6="$(ARCHRICING_ASSUME_ARCH=1 ARCHRICING_MKARCHISO_BIN=/nonexistent/mkarchiso bash "$ROOT/build.sh" --check-only < /dev/null 2>&1)"; RC=$?
[[ $RC -ne 0 && "$OUT6" == *"missing dependencies"* && "$OUT6" != *"SUCCESSFUL"* ]] \
  && ok "missing mkarchiso clean error" || ko "missing mkarchiso clean error (rc=$RC)"

# --- 7. package validation names the culprit ---------------------------------------
OUT7="$(ARCHRICING_ASSUME_ARCH=1 ARCHRICING_NO_SUDO=1 ARCHRICING_MKARCHISO_BIN="$T/mkarchiso-fake" ARCHRICING_PACMAN_BIN="$T/pacman-stub" FAKE_PACMAN_MISSING="kitty" bash "$ROOT/build.sh" < /dev/null 2>&1)"; RC=$?
[[ $RC -ne 0 && "$OUT7" == *"PACKAGE VALIDATION FAILED"* && "$OUT7" == *"- kitty"* ]] \
  && ok "package validation names kitty" || ko "package validation names kitty (rc=$RC)"

# --- 8. AUR leak refused explicitly -------------------------------------------------
mkdir -p "$T/prof2"; cp -a "$ROOT/iso/profile/." "$T/prof2/"
echo "yay-bin" >> "$T/prof2/packages.x86_64"
OUT8="$(ARCHRICING_ASSUME_ARCH=1 ARCHRICING_NO_SUDO=1 ARCHRICING_MKARCHISO_BIN="$T/mkarchiso-fake" ARCHRICING_PROFILE_DIR="$T/prof2" ARCHRICING_PACMAN_BIN="$T/pacman-stub" FAKE_PACMAN_MISSING="yay-bin" bash "$ROOT/build.sh" < /dev/null 2>&1)"; RC=$?
[[ $RC -ne 0 && "$OUT8" == *"yay-bin"* && "$OUT8" == *"AUR"* ]] \
  && ok "AUR leak refused (yay-bin)" || ko "AUR leak refused (rc=$RC)"

# --- 9. failing mkarchiso + stale ISO -> FAILED, never SUCCESSFUL -------------------
HAD_OUT=0; [[ -d "$ROOT/out" ]] && HAD_OUT=1
STALE="$ROOT/out/archricing-stale-$$.iso"
mkdir -p "$ROOT/out"; printf 'STALE-NOT-ISO' > "$STALE"; touch -d '2020-01-01' "$STALE"
OUT9="$(ARCHRICING_ASSUME_ARCH=1 ARCHRICING_NO_SUDO=1 ARCHRICING_PACMAN_BIN="$T/pacman-stub" ARCHRICING_MKARCHISO_BIN="$T/mkarchiso-probe-ok-fail-run" bash "$ROOT/build.sh" < /dev/null 2>&1)"; RC=$?
rm -f "$STALE"
[[ $RC -ne 0 && "$OUT9" == *"ARCHRICING ISO BUILD FAILED"* && "$OUT9" != *"SUCCESSFUL"* ]] \
  && ok "failing mkarchiso -> FAILED banner" || ko "failing mkarchiso banner (rc=$RC)"

# --- 10. full fake pipeline -> SUCCESSFUL + ISO + SHA256SUMS + log ------------------
FREE_KB="$(df -k "$ROOT" | awk 'NR==2 {print $4}')"
if [[ "${FREE_KB:-0}" -lt 8388608 ]]; then
  echo "SKIP: full fake pipeline (<8GB free under $ROOT)"
else
  OUT10="$(ARCHRICING_ASSUME_ARCH=1 ARCHRICING_NO_SUDO=1 ARCHRICING_PACMAN_BIN="$T/pacman-stub" ARCHRICING_MKARCHISO_BIN="$T/mkarchiso-fake" bash "$ROOT/build.sh" < /dev/null 2>&1)"; RC=$?
  ISO10="$(ls -t "$ROOT"/out/archricing-fake-*.iso 2>/dev/null | head -n1 || true)"
  if [[ $RC -eq 0 && -n "${ISO10:-}" && "$OUT10" == *"ARCHRICING ISO BUILD SUCCESSFUL"* && "$OUT10" == *"$(basename "$ISO10")"* ]]; then
    ok "fake pipeline SUCCESSFUL names fresh ISO"
  else
    ko "fake pipeline SUCCESSFUL (rc=$RC)"
  fi
  if [[ -n "${ISO10:-}" && -f "$ISO10" ]]; then
    ( cd "$ROOT/out" && sha256sum -c SHA256SUMS >/dev/null 2>&1 ) && ok "SHA256SUMS verifies" || ko "SHA256SUMS verifies"
    [[ -s "$ROOT/out/build.log" ]] && grep -q "mkarchiso exit: 0" "$ROOT/out/build.log" && ok "build.log complete" || ko "build.log complete"
    rm -f "$ROOT"/out/archricing-fake-*.iso
    [[ "$HAD_OUT" -eq 0 ]] && rm -rf "$ROOT/out" "$ROOT/.build" || rm -rf "$ROOT/.build"
  else
    ko "fake ISO file exists"
  fi
fi

# --- 11. --clean --------------------------------------------------------------------
bash "$ROOT/build.sh" --clean >/dev/null 2>&1 && ok "--clean" || ko "--clean"

echo "== test-build: $PASS passed, $FAILN failed =="
[[ "$FAILN" -eq 0 ]]
