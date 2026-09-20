#!/usr/bin/env bash
# scripts/post-install.sh — exécuté par Calamares (shellprocess@archricing-postinstall,
# en chroot sur la cible) + relançable manuellement sur système installé.
# Applique /etc/archricing/install-profile.conf (choix page "ArchRicing Experience",
# défauts = configs/install-profile.default.conf). Idempotent.
# Usage manuel : sudo [ARCHRICING_USER=<login>] ./scripts/post-install.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "/usr/share/archricing/configs" ]]; then ASSETS="/usr/share/archricing";
elif [[ -d "$SCRIPT_DIR/../configs" ]]; then ASSETS="$SCRIPT_DIR/..";
else echo "ERREUR: assets ArchRicing introuvables" >&2; exit 1; fi

USER_NAME="${1:-${ARCHRICING_USER:-${SUDO_USER:-}}}"
if [[ -z "$USER_NAME" || "$USER_NAME" == "root" ]]; then
  USER_NAME="$(awk -F: '$3>=1000 && $3<60000 {print $1; exit}' /etc/passwd 2>/dev/null || true)"
fi
[[ -n "$USER_NAME" ]] || { echo "ERREUR: aucun utilisateur cible (export ARCHRICING_USER=<login>)" >&2; exit 1; }
USER_HOME="$(eval echo "~$USER_NAME")"
[[ -d "$USER_HOME" ]] || { echo "ERREUR: HOME introuvable pour $USER_NAME" >&2; exit 1; }
USER_GROUP="$(id -gn "$USER_NAME" 2>/dev/null || echo "$USER_NAME")"
msg(){ printf '\033[1;35m[archricing]\033[0m %s\n' "$*"; }

# ---- Profil (Calamares > défauts) -------------------------------------------
PROFILE="/etc/archricing/install-profile.conf"
[[ -f "$PROFILE" ]] || { mkdir -p /etc/archricing; cp -a "$ASSETS/configs/install-profile.default.conf" "$PROFILE"; }
# shellcheck disable=SC1090
set -a; source "$PROFILE"; set +a
: "${EDITION:=normal}" "${THEME:=sakura}" "${WALLPAPER:=archricing-sakura.svg}"
: "${DOCK:=floating}" "${TOP_PANEL:=on}" "${TRANSPARENCY:=on}" "${BLUR:=on}"
: "${ANIMATIONS:=on}" "${WOBBLY:=normal}" "${ROUNDED:=on}"
: "${ICONS:=Papirus-Dark}" "${CURSOR:=Bibata-Modern-Ice}" "${TERMINAL:=kitty}"
: "${FASTFETCH:=on}" "${SHELL:=zsh}" "${STARSHIP:=on}" "${WELCOME:=on}"
: "${SETTINGS_APP:=installed}" "${SOFTWARE_APP:=installed}" "${UPDATE_APP:=installed}"
[[ "$ANIMATIONS" == "performance" ]] && { WOBBLY="off"; BLUR="off"; }
msg "Profil : EDITION=$EDITION THEME=$THEME DOCK=$DOCK PANEL=$TOP_PANEL WOBBLY=$WOBBLY TERM=$TERMINAL SHELL=$SHELL"

msg "Activation services essentiels…"
systemctl enable sddm NetworkManager bluetooth 2>/dev/null || true

# ---- Base KDE/Kitty/Fastfetch/Starship ---------------------------------------
for f in kwinrc kdeglobals plasmarc kcminputrc; do
  [[ -f "$ASSETS/configs/kde/$f" ]] || { echo "WARN: kde/$f manquant, skip"; continue; }
  install -Dm644 "$ASSETS/configs/kde/$f" "$USER_HOME/.config/$f"
done
# Layout dock × top panel (variantes générées ; repli : floating-panel)
VARIANT="plasma-$DOCK-$([ "$TOP_PANEL" = on ] && echo panel || echo nopanel).conf"
[[ "$DOCK" == "none" && "$TOP_PANEL" == "off" ]] && VARIANT="plasma-none-nopanel.conf"  # = none-panel (repli)
[[ -f "$ASSETS/configs/kde/variants/$VARIANT" ]] || VARIANT="plasma-floating-panel.conf"
install -Dm644 "$ASSETS/configs/kde/variants/$VARIANT" "$USER_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
msg "Layout : $VARIANT"

# ---- Thème / icônes / curseur -------------------------------------------------
sed -i "s/^ColorScheme=.*/ColorScheme=ArchRicing${THEME^}/" "$USER_HOME/.config/kdeglobals" 2>/dev/null || true
sed -i "s/^Theme=.*/Theme=$ICONS/" "$USER_HOME/.config/kdeglobals" 2>/dev/null || true
sed -i "s/^cursorTheme=.*/cursorTheme=$CURSOR/" "$USER_HOME/.config/kcminputrc" 2>/dev/null || true
# Coins arrondis (breeze ; visuel à confirmer sur Plasma réel — voir BUILD_STATUS)
if [[ "$ROUNDED" == on ]]; then RADIUS=6; else RADIUS=0; fi
printf '[Windeco]\nroundCorners=%s\ncornerRadius=%s\n' "$([ "$ROUNDED" = on ] && echo true || echo false)" "$RADIUS" > "$USER_HOME/.config/breezerc"

# ---- Effets : transparence / blur / animations / wobbly -----------------------
if [[ "$TRANSPARENCY" == off ]]; then
  sed -i 's/^background_opacity.*/background_opacity 1.0/' "$ASSETS/configs/kitty/kitty.conf" 2>/dev/null || true
fi
install -Dm644 "$ASSETS/configs/kitty/kitty.conf" "$USER_HOME/.config/kitty/kitty.conf"
[[ "$BLUR" == off ]] && sed -i 's/^blurEnabled=.*/blurEnabled=false/' "$USER_HOME/.config/kwinrc" || true
if [[ "$ANIMATIONS" == off || "$ANIMATIONS" == "performance" ]]; then
  sed -i 's/^AnimationsDuration=.*/AnimationsDuration=100/; s/^AnimationSpeed=.*/AnimationSpeed=5/' "$USER_HOME/.config/kwinrc"
fi
case "$WOBBLY" in
  off)     sed -i 's/^wobblywindowsEnabled=.*/wobblywindowsEnabled=false/' "$USER_HOME/.config/kwinrc" ;;
  subtle)  sed -i 's/^wobblywindowsEnabled=.*/wobblywindowsEnabled=true/; s/^WobblynessLevel=.*/WobblynessLevel=0/' "$USER_HOME/.config/kwinrc" ;;
  playful) sed -i 's/^wobblywindowsEnabled=.*/wobblywindowsEnabled=true/; s/^WobblynessLevel=.*/WobblynessLevel=2/' "$USER_HOME/.config/kwinrc" ;;
  *)       sed -i 's/^wobblywindowsEnabled=.*/wobblywindowsEnabled=true/; s/^WobblynessLevel=.*/WobblynessLevel=1/' "$USER_HOME/.config/kwinrc" ;;
esac

# ---- Shell / fastfetch / starship ----------------------------------------------
install -Dm644 "$ASSETS/configs/fastfetch/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc"
install -Dm644 "$ASSETS/configs/fastfetch/logo-ascii.txt" "$USER_HOME/.local/share/archricing/logo-ascii.txt"
install -Dm644 "$ASSETS/configs/starship/starship.toml" "$USER_HOME/.config/starship.toml"
install -Dm644 "$ASSETS/configs/zsh/.zshrc" "$USER_HOME/.zshrc"
if [[ "$FASTFETCH" == off ]]; then
  python3 - "$USER_HOME/.zshrc" <<'EOF'
import re, sys
p = sys.argv[1]
s = open(p).read()
s = re.sub(r"# Fastfetch uniquement.*?(?= # PATH local)", "", s, flags=re.S)
open(p, "w").write(s)
EOF
fi
[[ "$STARSHIP" == off ]] && sed -i 's/^command -v starship.*/# starship désactivé (profil)/' "$USER_HOME/.zshrc" || true
if [[ "$SHELL" == bash ]]; then chsh -s /usr/bin/bash "$USER_NAME" 2>/dev/null || true;
else command -v zsh >/dev/null && chsh -s /usr/bin/zsh "$USER_NAME" 2>/dev/null || true; fi

install -Dm644 "$ASSETS/configs/sddm/sddm.conf" /etc/sddm.conf.d/archricing.conf
chown -R "$USER_NAME:$USER_GROUP" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/.zshrc" 2>/dev/null || true
rm -f /etc/sddm.conf.d/archricing-autologin.conf   # jamais d'autologin installé

# ---- Wallpapers + thèmes -------------------------------------------------------
mkdir -p /usr/share/backgrounds/archricing /usr/share/archricing/themes
cp -a "$ASSETS"/wallpapers/*.svg /usr/share/backgrounds/archricing/ 2>/dev/null || echo "WARN: wallpapers manquants"
for t in "$ASSETS"/themes/*/theme.json; do
  n="$(basename "$(dirname "$t")")"
  cp -a "$t" "/usr/share/archricing/themes/$n.json"
done

# ---- CLI + apps (selon profil) --------------------------------------------------
install -Dm755 "$ASSETS/scripts/archrichting" /usr/local/bin/archricing 2>/dev/null || install -Dm755 "$ASSETS/scripts/archricing" /usr/local/bin/archricing
install -Dm755 "$ASSETS/scripts/archricing-terminal-exec" /usr/local/bin/archricing-terminal-exec
install -Dm755 "$ASSETS/scripts/validate-menu.sh" /usr/local/bin/archricing-validate-menu
mkdir -p /usr/share/archricing
cp -a "$ASSETS/apps" /usr/share/archricing/ 2>/dev/null || true
[[ "$SETTINGS_APP" == installed ]] && printf '#!/usr/bin/env bash\nexec python3 /usr/share/archricing/apps/settings/app.py "$@"\n' > /usr/local/bin/archricing-settings && chmod +x /usr/local/bin/archricing-settings || rm -rf /usr/share/archricing/apps/settings
[[ "$SOFTWARE_APP" == installed ]] || rm -rf /usr/share/archricing/apps/software-center
[[ "$UPDATE_APP" == installed ]] || rm -rf /usr/share/archricing/apps/updates
[[ "$WELCOME" == on ]] && printf '#!/usr/bin/env bash\nexec python3 /usr/share/archricing/apps/welcome/app.py "$@"\n' > /usr/local/bin/archricing-welcome && chmod +x /usr/local/bin/archricing-welcome || rm -rf /usr/share/archricing/apps/welcome

msg "Hardware…"
bash "$ASSETS/scripts/hardware-detect.sh" 2>/dev/null || true
lspci 2>/dev/null | grep -qi nvidia && msg "NVIDIA détecté -> pacman -S nvidia-open nvidia-utils egl-wayland" || true

# ---- Édition SECURITY -----------------------------------------------------------
if [[ "$EDITION" == "security" ]]; then
  msg "Édition SECURITY : suite officielle + menu + service AUR…"
  OFFICIAL="$(grep -vE '^\s*(#|$)' "$ASSETS/packages/security/security-official.txt")"
  # shellcheck disable=SC2086
  pacman -S --needed --noconfirm $OFFICIAL || echo "WARN: certains paquets security ont échoué (voir pacman)"
  SECMENU=/usr/share/applications/archricing-security
  mkdir -p "$SECMENU" /usr/share/desktop-directories
  cp -a "$ASSETS/packages/security/menu/applications/"*.desktop "$SECMENU/" 2>/dev/null || echo "WARN: menu non généré (lancer generate-menu.py)"
  cp -a "$ASSETS/packages/security/menu/directories/"*.directory /usr/share/desktop-directories/ 2>/dev/null || true
  bash "$ASSETS/scripts/validate-menu.sh" "$SECMENU" || true
  install -Dm755 "$ASSETS/scripts/install-security-aur.sh" /usr/local/bin/archricing-install-security-aur
  sed "s/@USER@/$USER_NAME/g" "$ASSETS/configs/systemd/archricing-security-aur.service" > /etc/systemd/system/archricing-security-aur.service
  touch /etc/archricing/security-aur.pending
  systemctl enable archricing-security-aur.service 2>/dev/null || true
  cat > /etc/archricing/SECURITY-NOTICE.txt <<'EOF'
ArchRicing SECURITY : ces outils sont destinés UNIQUEMENT aux systèmes et
environnements pour lesquels vous disposez d'une autorisation explicite.
Aucun outil n'est exécuté automatiquement. Voir docs/security.md.
EOF
fi

# ---- Welcome autostart ------------------------------------------------------------
mkdir -p "$USER_HOME/.config/autostart"
if [[ "$WELCOME" == on ]]; then
  cat > "$USER_HOME/.config/autostart/archricing-welcome.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Welcome to ArchRicing
Exec=archricing-welcome
Icon=archricing
X-GNOME-Autostart-enabled=true
EOF
  touch "$USER_HOME/.config/archricing-first-run"
  chown -R "$USER_NAME:$USER_GROUP" "$USER_HOME/.config/autostart" "$USER_HOME/.config/archricing-first-run" 2>/dev/null || true
else
  rm -f "$USER_HOME/.config/autostart/archricing-welcome.desktop" "$USER_HOME/.config/archricing-first-run"
fi
msg "Post-install OK (profil $PROFILE)."
