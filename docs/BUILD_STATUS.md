# BUILD STATUS — audits pré-build réel (Phase 2 + Phase 3 éditions)

> Environnement d'audit : **Windows** (pas de build ISO possible ici).
> Tout ce qui exige mkarchiso/pacman/QEMU/Plasma est marqué **NOT VERIFIED**
> et doit être validé sur Arch Linux (voir `docs/build-windows.md`).
> Date d'audit : 2026-09-20. Commande recommandée : `./scripts/build-iso.sh`.
> `tests/check-tree.sh` a été **réellement exécuté** via WSL bash le 2026-09-20 :
> `ALL CHECKS PASSED` (bash -n, py_compile, wobbly, no-tiling, placement,
> kitty, pacman.conf, bad-packages, editions sync, menu 54 outils, profile keys).
> Les générateurs (`generate-menu.py`, `generate-variants.py`) ont été **réellement
> exécutés** (54 .desktop + 12 .directory + 6 variantes, contenus spot-vérifiés).
> Rien d'autre n'a été exécuté.

## VERIFIED (vérifié statiquement sur Windows)

| # | Élément | Ce qui a été vérifié | Comment |
|---|---|---|---|
| 1 | Arborescence | 70+ fichiers présents, chemins repo-relatifs uniquement | `tests/check-tree.sh` + listing |
| 2 | `profiledef.sh` | `iso_label="ARCHRICING"` court (FAT-safe) ; `pacman.conf` référencé ; `file_permissions` = fichiers réellement embarqués (`archricing`, `archricing-postinstall`, `archrichting-settings`, `archricing-welcome`, `customize_airootfs.sh`) | relecture |
| 3 | `pacman.conf` + `bootstrap_packages.x86_64` | fichiers créés (bloquants mkarchiso, absents avant l'audit) | relecture |
| 4 | `packages.x86_64` | `calamares-configs` supprimé (n'existe pas en extra) ; `sudo` + `edk2-shell` ajoutés ; pas de doublon | relecture + scan |
| 5 | Listes `packages/*` | `p7zip`→`7zip` ; `qcoro-qt6`→`qcoro` ; `ttf-font-nerd` et ligne `wallpapers` supprimés (paquets inexistants) | scan `bad-packages` de check-tree |
| 6 | Calamares — nom d'instance | `settings.conf` référence `shellprocess@archricing-postinstall` et le fichier s'appelle désormais `shellprocess@archricing-postinstall.conf` (l'ancien nom avec tiret est détecté comme erreur par check-tree) | relecture |
| 7 | Calamares — modules minimaux | `displaymanager.conf` (force sddm), `unpackfs.conf` (source `airootfs.sfs`), `services-systemd.conf` (sddm/NetworkManager/graphical), `packages.conf` (backend pacman) présents | relecture |
| 8 | KWin floating/no-tiling | `tileEnabled=false`, `quicktileEnabled=false`, `Placement=Centered` (sans espace parasite), aucun tiling, aucune interception khotkeys | grep |
| 9 | Wobbly | `wobblywindowsEnabled=true` (plugin KWin natif, pas de dépendance externe), niveaux OFF/SUBTLE/NORMAL/PLAYFUL documentés | grep |
| 10 | Kitty | `background_opacity 0.72` + `background_blur 24`, jamais opaque par défaut | grep |
| 11 | Fastfetch | `config.jsonc` JSON valide, logo ASCII original présent | `python -c json.load` |
| 12 | Thèmes | 7× `theme.json` valides ; `midnight` pointe désormais vers `archricing-midnight.svg` qui existe | `python -c json.load` + listing |
| 13 | Zsh/Starship | `.zshrc` sans raccourcis exotiques, fastfetch 1er terminal, chemins fzf Arch corrects ; `starship.toml` valide | relecture |
| 14 | `archricing` CLI | plus de crash `set -u` sur `$XDG_SESSION_TYPE` (`${XDG_SESSION_TYPE:-unknown}`) ; syntaxe `bash -n` OK (inclus explicitement, le glob `*.sh` le manquait) | relecture + bash -n sous Git Bash |
| 15 | `install.sh` | `grep -h` (avant : préfixes `fichier:` injectés dans `pacman -S`) | relecture |
| 16 | `post-install.sh` | résout ses assets via `/usr/share/archricing` (système installé) puis repo ; détecte l'utilisateur (arg/`ARCHRICING_USER`/`SUDO_USER`/1er UID≥1000, refuse root seul) ; `chown` sur groupe primaire réel ; boucle de copie des thèmes sans écrasement (`$n.json`) ; ne copie jamais l'autologin live ; installe les wrappers `archricing-settings`/`archricing-welcome` | relecture |
| 17 | Live session | `customize_airootfs.sh` (user `liveuser`, `systemctl enable sddm NetworkManager bluetooth`, autologin live, skel+Desktop install) + entrée `archricing-install.desktop` présents | relecture |
| 18 | QEMU | `-soundhw` (supprimé QEMU 9) → `intel-hda`+`hda-duplex` ; `-net` legacy → `-nic user,model=virtio-net-pci` ; garde-fou OVMF manquant | relecture |
| 19 | Portabilité Windows | `.gitattributes` (LF forcé pour sh/py/conf/desktop) + `.gitignore` (`out/`, `work/`, `*.bak-*`) ; `check-tree.sh` portable (bash+grep+python3, OK Git Bash/MSYS2/WSL, pas de pacman/mkarchiso) | relecture |
| 20 | Chemins absolus | aucun `C:\`, `/home/<user>`, `/mnt/` dans paquets/scripts/configs | Select-String |
| 21 | Éditions (Phase 3) | `security-official.txt` (extra : masscan/wpscan/mullvad-vpn corrigés après vérification web) ; `security-aur.txt` avec confiance+fallback ; `packagechooser@edition.conf` synchronisé (pré-vol build + check-tree) ; `settings.conf` inclut `packagechooser@edition` + `archricing_experience` (show+exec) | check-tree "editions sync OK" |
| 22 | Menu Security (Phase 3) | `security-tools.json` valide ; 54 `.desktop` + 12 `.directory` générés ; chaque pkg présent dans official/aur ; `validate-menu.sh` auto-désactive les binaires absents ; CLI via `archricing-terminal-exec` (kitty/konsole/system selon profil) | exécution réelle du générateur + check "menu OK" |
| 23 | Profil Experience (Phase 3) | `install-profile.default.conf` (19 clés) == clés du module Calamares ; job d'écriture `/etc/archricing/install-profile.conf` ; `post-install.sh` applique dock×panel (6 variantes générées), transparence, blur, animations/performance, wobbly, coins, icônes, curseur, terminal, shell, fastfetch, starship, welcome, apps, édition Security (pacman + menu + service AUR + notice légale) | check "profile keys OK" + relecture |

## NOT VERIFIED (exige une vraie machine Arch Linux — jamais prétendu testé ici)

- `mkarchiso` : build réel (`./scripts/build-iso.sh`), taille ISO, `SHA256SUMS`.
- Boot BIOS + UEFI (QEMU `test-qemu.sh`), session live Plasma autologin `liveuser`.
- Rendu : transparence/blur Kitty, wobbly, dock/panneau, wallpapers, SDDM.
- Réseau (NetworkManager/iwd), audio (PipeWire), Bluetooth, batterie/laptop, NVIDIA.
- Calamares de bout en bout : ext4, Btrfs, LUKS, swap, profils Desktop/Full/Security.
- First boot installé : même bureau que le live, Welcome une seule fois, updates.
- `validate-packages.sh` (`pacman -Si` sur chaque paquet officiel).
- Bits exécutables git (`git update-index --chmod=+x`, impossible depuis NTFS) — voir guide Windows.
- TOUTE la Phase 3 sur système réel : page Calamares "Choose your ArchRicing edition"
  (packagechooser radio), page "ArchRicing Experience" (module PythonQt), job
  `install-profile.conf`, application du profil au 1er boot, variantes dock/panel.
- Édition Security installée : suite officielle complète, menu Security affiché et
  groupé dans Kickoff, lancement GUI + CLI de chaque outil, service AUR au 1er boot.
- Coins arrondis : clé `breezerc` écrite mais rendu NON vérifié (natif KWin incertain).
- Binaires présumés (`r2`, `mullvad-vpn`, `httpx`, `sherlock`, `rockyou`, `dirbuster`,
  `photon`, `recon-ng`, `responder`, `python-impacket`) : `validate-menu.sh` et
  `install-security-aur.sh` les filtrent proprement, mais les noms exacts restent
  à confirmer via `pacman -Si` / AUR au moment du build.

## KNOWN ISSUES

1. **KWin #474196** : le blur peut scintiller pendant le wobble (Wayland). Fix partiel dès KWin 6.4. Contournement : Wobbly → SUBTLE. Non bloquant pour le build.
2. **Branding Calamares** : `logo.png`/`welcome.png`/`show.qml` référencés mais non fournis → Calamares affichera des emplacements vides, n'empêche pas l'installation. TODO : ajouter les assets.
3. **`oxygen`/`oxygen-sounds`/`yakuake`/`hplip`** : existent en extra mais alourdissent ; à réévaluer après le premier boot (diète éventuelle).
4. **Paquets AUR/Security** : non vérifiables ici ; alternatives documentées dans les listes.
5. **NVIDIA Wayland** : potentiel glitches (driver `nvidia-open` recommandé, voir troubleshooting).
6. **`inter-font`** : nom exact à confirmer via `pacman -Si` au premier `validate-packages.sh`.
