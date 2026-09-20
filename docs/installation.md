# Installation — ArchRicing

## 1. Build (sur Arch Linux — 3 commandes)

```bash
git clone https://github.com/K0rkkow/archricing.git
cd archricing
./build.sh
# -> out/archricing-YYYY.MM.DD-x86_64.iso + out/SHA256SUMS
```

`./build.sh` est le point d'entrée unique : il vérifie la compatibilité,
propose d'installer les dépendances manquantes (archiso, …) avec pacman
(confirmation demandée), prépare l'environnement, lance le build et vérifie
l'ISO produite. Sur Arch il build en natif ; sur Fedora/Debian/Ubuntu (et
autres), il build automatiquement dans un conteneur `archlinux:latest`
(podman ou docker) — l'ISO est toujours produite par archiso/mkarchiso.
Les scripts de `scripts/` et `iso/` sont des détails internes (dépréciés
comme points d'entrée).
Options utiles : `./build.sh --help`, `./build.sh --check-only` (pré-vol sans
build), `./build.sh --clean` (nettoyage). Chaque build écrit `out/build.log`.

Prérequis optionnels pour les tests graphiques : `sudo pacman -S edk2-ovmf qemu-desktop`.

## 2. Test QEMU

```bash
./tests/test-qemu.sh uefi   # ou bios
# Checklist : boot, souris, clavier, terminal transparent, wobbly, dock, launcher,
# réseau, audio, Calamares, 1er boot, updates.
```

## 3. Clé USB

```bash
sudo dd if=out/archricing-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
# ou : sudo ventoy / et copier l'ISO
```

## 4. Installateur Calamares

Welcome to ArchRicing → Install ArchRicing. Éditions : NORMAL / SECURITY
(choix "Choose your ArchRicing edition"), puis page "ArchRicing Experience"
(personnalisation graphique, enregistrée dans /etc/archricing/install-profile.conf).
Partitionnement : auto, manuel, ext4, Btrfs, LUKS, swap. UEFI + BIOS supportés.
Après reboot : même bureau que le live (post-install rejoue configs + skel).
