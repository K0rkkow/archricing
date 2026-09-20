#!/usr/bin/env bash
# scripts/reset.sh — restaure thème/dock/panel/animations/terminal/wallpapers/KDE sans réinstaller.
# Sauvegarde systématique avant écrasement. Idempotent.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
backup(){ [[ -e "$1" ]] && cp -a "$1" "$1.bak-$TS" && echo "backup: $1.bak-$TS"; }
echo "== Reset ArchRicing ($TS) =="
for f in ~/.config/kwinrc ~/.config/kdeglobals ~/.config/plasmashellrc ~/.config/plasmarc ~/.config/kitty/kitty.conf ~/.config/fastfetch/config.jsonc ~/.config/starship.toml ~/.zshrc; do backup "$f"; done
install -Dm644 "$ROOT/configs/kde/kwinrc" ~/.config/kwinrc
install -Dm644 "$ROOT/configs/kde/kdeglobals" ~/.config/kdeglobals
install -Dm644 "$ROOT/configs/kde/plasma-org.kde.plasma.desktop-appletsrc" ~/.config/plasma-org.kde.plasma.desktop-appletsrc
install -Dm644 "$ROOT/configs/kde/plasmarc" ~/.config/plasmarc
install -Dm644 "$ROOT/configs/kde/kcminputrc" ~/.config/kcminputrc
install -Dm644 "$ROOT/configs/kitty/kitty.conf" ~/.config/kitty/kitty.conf
install -Dm644 "$ROOT/configs/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
install -Dm644 "$ROOT/configs/fastfetch/logo-ascii.txt" ~/.local/share/archricing/logo-ascii.txt
install -Dm644 "$ROOT/configs/starship/starship.toml" ~/.config/starship.toml
install -Dm644 "$ROOT/configs/zsh/.zshrc" ~/.zshrc
sudo install -Dm644 "$ROOT/themes/sakura/theme.json" /usr/share/archricing/themes/sakura.json 2>/dev/null || true
qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || kwin_wayland --replace >/dev/null 2>&1 &
echo "OK — déconnexion/reconnexion recommandée."
