# DOCUMENTATION STATUS — what the website may claim (audited 2026-09-20)

Source of truth: the repository itself (inspected file by file).
Website labels: `Implemented` / `Partial` / `Planned` / `Not yet available`.
Rule: **no ISO has ever been built or booted** — the site must never claim otherwise.

## IMPLEMENTED (present in repo, statically verified)

- Single build entry point `./build.sh` (+ `--help/--check-only/--clean`, preflight,
  sudo-once, ISO+SHA256SUMS verification) — `build.sh`
- archiso profile (`profiledef.sh`, `packages.x86_64`, `pacman.conf`,
  `bootstrap_packages.x86_64`) — never executed
- Live session wiring (`customize_airootfs.sh`, liveuser, SDDM autologin drop-in,
  services, Install desktop entry) — never booted
- Calamares flow: `settings.conf`, edition choice (`packagechooser@edition`,
  NORMAL vs SECURITY radio), `archricing_experience` module writing
  `/etc/archricing/install-profile.conf` (20 keys), displaymanager/unpackfs/
  services/shellprocess modules — never run in a real installer
- `post-install.sh` applying the profile (layout variants, effects, shell,
  apps on/off, Security suite + menu + first-boot AUR service) — never executed
- `archricing` CLI: `theme wallpapers settings update info diagnose reset`
- Apps (Tkinter, present, syntax-checked, never launched on Plasma):
  Settings (Appearance/Terminal/Windows/System tabs), Welcome (first-run),
  Software Center (pacman search/install/update via pkexec), Updates
  (checkupdates list + Update button)
- KDE configs: floating-only `kwinrc` (wobbly native, no tiling keys), dock +
  top panel layout, 6 generated layout variants, `kdeglobals`, SDDM conf
- Kitty transparent (`background_opacity 0.72` + blur 24), Fastfetch theme +
  original ASCII logo, Zsh (first-terminal fastfetch) + Starship theme
- 7 themes (JSON), 9 SVG wallpapers, Security menu data (54 `.desktop` +
  12 `.directory` generated), `archricing-terminal-exec`, `validate-menu.sh`
- Docs: installation, customization, development, security, troubleshooting,
  editions, build-windows, BUILD_STATUS

## PARTIAL (files exist, behavior unverified or incomplete)

- Rounded corners: `breezerc` keys written by post-install — rendering on real
  KWin **UNKNOWN**
- Security menu grouping in Kickoff: `.directory` files shipped, visual grouping
  **NOT VERIFIED** (entries remain name-searchable regardless)
- AUR package names (`httpx`, `sherlock`, `rockyou`, `dirbuster`, `photon`,
  `recon-ng`, `responder`, `python-impacket`) and binaries (`r2`, `mullvad-vpn`):
  filtered safely at install time, exact names re-verified at build
- Calamares branding images (`logo.png`, `welcome.png`, `show.qml`): referenced,
  not shipped (installer works, slots render empty)
- `inter-font`, `oxygen`, `yakuake`, `hplip`: listed, weight to re-evaluate
- First-boot AUR service: unit + script written, never executed

## PLANNED (not in repo)

- Real ISO build (`mkarchiso`) and SHA256SUMS artifact
- UEFI/BIOS boot, live Plasma session, Calamares end-to-end (ext4/Btrfs/LUKS/swap)
- Installed-system first boot, applied Experience profile, Security menu launch tests
- Public ISO download (Releases section empty)
- FR translation of the website (architecture ready, EN primary)

## UNKNOWN (depends on hardware/upstream at build time)

- Wobbly + blur rendering quality (upstream KWin bug #474196 flicker)
- NVIDIA Wayland behavior (`nvidia-open` recommended)
- Exact upstream package availability on build day (re-check via
  `tests/validate-packages.sh`)
