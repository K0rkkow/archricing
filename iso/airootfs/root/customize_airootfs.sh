#!/usr/bin/env bash
# iso/airootfs/root/customize_airootfs.sh — exécuté par mkarchiso DANS l'airootfs
# au moment du build (mécanisme standard archiso). Crée le live user, active les
# services graphiques/réseau et déploie la config ArchRicing pour la session live.
# Idempotent. NE JAMAIS y mettre de scan réseau ou d'action automatique.
set -euo pipefail
ASSETS="/usr/share/archricing"
LIVE_USER="liveuser"

# 1. Live user (groupe wheel pour sudo via polkit/sudoers.d si présent)
if ! id "$LIVE_USER" >/dev/null 2>&1; then
  useradd -m -G wheel -s /usr/bin/zsh "$LIVE_USER"
  passwd -d "$LIVE_USER"   # pas de mot de passe en live
fi

# 2. Services : graphique + réseau + bluetooth (créent les symlinks .wants)
systemctl enable sddm NetworkManager bluetooth

# 3. SDDM : autologin liveuser en Wayland/Plasma (fichier déjà présent via airootfs,
#    on le (ré)écrit ici pour garantir la cohérence même si l'overlay a bougé)
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/archricing-autologin.conf <<EOF
[Autologin]
User=$LIVE_USER
Session=plasma
EOF

# 4. Config ArchRicing -> skel (nouveaux utilisateurs) + liveuser courant
for f in kwinrc kdeglobals plasma-org.kde.plasma.desktop-appletsrc plasmarc kcminputrc; do
  if [[ -f "$ASSETS/kde/$f" ]]; then
    install -Dm644 "$ASSETS/kde/$f" "/etc/skel/.config/$f"
    install -Dm644 "$ASSETS/kde/$f" "/home/$LIVE_USER/.config/$f"
  fi
done
[[ -f "$ASSETS/kitty/kitty.conf" ]] && { install -Dm644 "$ASSETS/kitty/kitty.conf" /etc/skel/.config/kitty/kitty.conf; install -Dm644 "$ASSETS/kitty/kitty.conf" "/home/$LIVE_USER/.config/kitty/kitty.conf"; }
[[ -f "$ASSETS/fastfetch/config.jsonc" ]] && { install -Dm644 "$ASSETS/fastfetch/config.jsonc" /etc/skel/.config/fastfetch/config.jsonc; install -Dm644 "$ASSETS/fastfetch/config.jsonc" "/home/$LIVE_USER/.config/fastfetch/config.jsonc"; }
[[ -f "$ASSETS/fastfetch/logo-ascii.txt" ]] && { install -Dm644 "$ASSETS/fastfetch/logo-ascii.txt" /etc/skel/.local/share/archricing/logo-ascii.txt; install -Dm644 "$ASSETS/fastfetch/logo-ascii.txt" "/home/$LIVE_USER/.local/share/archricing/logo-ascii.txt"; }
[[ -f "$ASSETS/starship/starship.toml" ]] && { install -Dm644 "$ASSETS/starship/starship.toml" /etc/skel/.config/starship.toml; install -Dm644 "$ASSETS/starship/starship.toml" "/home/$LIVE_USER/.config/starship.toml"; }
[[ -f "$ASSETS/zsh/.zshrc" ]] && { install -Dm644 "$ASSETS/zsh/.zshrc" /etc/skel/.zshrc; install -Dm644 "$ASSETS/zsh/.zshrc" "/home/$LIVE_USER/.zshrc"; }
chown -R "$LIVE_USER:$LIVE_USER" "/home/$LIVE_USER"

# 5. Raccourci "Install ArchRicing" sur le bureau du liveuser
mkdir -p "/home/$LIVE_USER/Desktop"
cp -a /usr/share/applications/archricing-install.desktop "/home/$LIVE_USER/Desktop/" 2>/dev/null || true
chmod +x "/home/$LIVE_USER/Desktop/archricing-install.desktop" 2>/dev/null || true
chown -R "$LIVE_USER:$LIVE_USER" "/home/$LIVE_USER/Desktop"
echo "customize_airootfs: OK"
