#!/usr/bin/env bash
# scripts/diagnostics.sh — aussi exposé via `archricing diagnose`. Jamais de réseau auto.
set -uo pipefail
ok(){ printf '[OK] %s\n' "$*"; }; ko(){ printf '[KO] %s\n' "$*"; }
check(){ if eval "$2" >/dev/null 2>&1; then ok "$1"; else ko "$1"; fi; }
echo "== ArchRicing diagnose $(date -u +%Y-%m-%dT%H:%MZ) =="
check "GPU (glxinfo/vulkaninfo)" "command -v glxinfo || command -v vulkaninfo"
check "Wayland session" 'echo "$XDG_SESSION_TYPE" | grep -qi wayland'
check "KDE plasmashell" "pgrep -x plasmashell"
check "KWin wayland" "pgrep -af kwin_wayland"
check "Audio pipewire" "systemctl --user is-active pipewire"
check "NetworkManager" "systemctl is-active NetworkManager"
check "Bluetooth service" "systemctl is-active bluetooth || true"
check "SDDM" "systemctl is-enabled sddm"
check "Kitty config" "test -f ~/.config/kitty/kitty.conf"
check "Fastfetch theme" "test -f ~/.config/fastfetch/config.jsonc"
check "Disque racine <85%" 'test $(df / --output=pcent | tail -1 | tr -dc 0-9) -lt 85'
check "Mémoire dispo" "free | head -2 | tail -1"
echo "GPU: $(lspci 2>/dev/null | grep -i vga | head -1 || echo n/a)"
echo "Kernel: $(uname -r) | Plasma: $(plasmashell --version 2>/dev/null || echo n/a)"
