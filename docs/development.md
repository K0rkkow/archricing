# Development — build reproductible

- Profil archiso : `iso/profile/profiledef.sh` + `packages.x86_64` (fusion auto depuis `packages/*`).
- airootfs : skel + calamares + `/usr/local/bin` (voir `iso/airootfs/`).
- Scripts idempotents : `scripts/*.sh` (backup avant écrasement, `set -euo pipefail`).
- AUR : helper `yay-bin`, listes + alternatives dans `packages/aur/`.
- Valider : `./tests/check-tree.sh` (partout) + `./tests/validate-packages.sh` (sur Arch) + `shellcheck`.
- Wobbly = plugin KWin natif (`wobblywindowsEnabled`), pas de dépendance externe.
- Dock = panneau Plasma natif flottant (latte-dock abandonné, incompatible Plasma 6).
