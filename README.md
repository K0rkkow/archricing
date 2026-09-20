# ArchRicing — Arch, but make it beautiful.

![ArchRicing](https://img.shields.io/badge/ArchRicing-beautiful%20Arch-ff7ac6?style=for-the-badge)
![Base](https://img.shields.io/badge/base-Arch%20Linux-1793d1?style=flat-square)
![Desktop](https://img.shields.io/badge/desktop-KDE%20Plasma%206%20Wayland-1e1e2e?style=flat-square)
![License](https://img.shields.io/badge/license-GPL--3.0-green?style=flat-square)
![CI](https://github.com/K0rkkow/archricing/actions/workflows/ci.yml/badge.svg)

> **Floating desktop. Mouse-first. No tiling. No mandatory shortcuts. Beautiful by default.**

## État du projet (honnête)

- ✅ Contrôles statiques : structure, syntaxe bash/Python, JSON, cohérence
  éditions/menu/profil — vérifiés en CI à chaque push (voir badge ci-dessus).
- ⬜ **Aucune ISO publiée pour l'instant** (section Releases vide) : le build
  `mkarchiso` exige une vraie machine Arch Linux et n'a pas encore été exécuté.
- ⬜ Boot UEFI/BIOS, live Plasma, Calamares, installs Normal/Security : **NOT VERIFIED**.
- Détail point par point : [`docs/BUILD_STATUS.md`](docs/BUILD_STATUS.md).
- Construire l'ISO (sur Arch) : [`docs/installation.md`](docs/installation.md).
  Depuis Windows : [`docs/build-windows.md`](docs/build-windows.md).

ArchRicing est une véritable distribution basée sur Arch Linux : une ISO préconfigurée
avec KDE Plasma 6 (Wayland), installateur graphique Calamares, dock translucide,
terminal Kitty transparent + blur, wobbly windows natif KWin, Fastfetch custom,
centre de personnalisation et toolkit sécurité optionnel.

Quelqu'un démarre l'ISO → voit immédiatement le bureau ArchRicing → clique
**Install ArchRicing** → retrouve exactement la même expérience après reboot.

**Ce n'est PAS un dotfiles repo, PAS un rice Hyprland.**

## Principes

1. **NO TILING BY DEFAULT** — tout est flottant, déplaçable/redimensionnable à la souris.
2. **MOUSE FIRST** — tout ce qui est important est cliquable.
3. **NO REQUIRED CUSTOM SHORTCUTS** — pas de Super+Q/W/1/2/3 imposé.
4. **EVERYTHING VISUAL SHOULD BE CUSTOMIZABLE** — sliders, switches, previews.
5. **BEAUTIFUL BY DEFAULT** — Sakura/Aurora/Ocean/Midnight/Dream/Cyber/Minimal.
6. **FAST AND RESPONSIVE** — GPU, pas de daemons inutiles, Performance Mode.
7. **DO NOT SACRIFICE USABILITY FOR AESTHETICS.**

## Démarrage rapide (sur Arch Linux)

```bash
git clone https://github.com/K0rkkow/archricing.git
cd archricing
./scripts/build-iso.sh        # build l'ISO -> out/archricing-YYYY.MM.DD-x86_64.iso
./tests/test-qemu.sh uefi     # teste en QEMU (UEFI)
```

Voir [`docs/installation.md`](docs/installation.md),
[`docs/customization.md`](docs/customization.md),
[`docs/development.md`](docs/development.md).

## Arborescence

```
archricing/
├── iso/            # profil archiso + airootfs + build.sh
├── calamares/      # branding + modules + settings
├── packages/       # listes core/desktop/personalization/security/aur
├── configs/        # kde / kitty / fastfetch / zsh / starship / sddm
├── wallpapers/     # 7 wallpapers SVG originaux (16:9, 16:10, 21:9, 4K)
├── themes/         # 7 thèmes JSON (sakura, aurora, ocean, midnight, dream, cyber, minimal)
├── scripts/        # build-iso, install, post-install, hardware-detect, diagnostics, reset, archricing CLI
├── apps/           # settings, software-center, welcome, updates
├── tests/          # tests QEMU + install
└── docs/           # installation, customization, development, security, troubleshooting
```

## Disclaimer

ArchRicing n'est pas une édition officielle d'Arch Linux.
« Arch Linux » est une marque reconnue du projet Arch Linux.
Les outils sécurité (`packages/security/`) sont fournis **uniquement** pour usage
légal sur des systèmes/environnements autorisés (voir `docs/security.md`).
Aucun scan/reconnaissance automatique n'est effectué.
