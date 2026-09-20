# Installation — ArchRicing

## 1. Build (sur Arch Linux)

```bash
sudo pacman -S archiso edk2-ovmf qemu-desktop shellcheck
git clone https://github.com/K0rkkow/archricing && cd archricing
./scripts/build-iso.sh
# -> out/archricing-YYYY.MM.DD-x86_64.iso + out/SHA256SUMS
```

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

Welcome to ArchRicing → Install ArchRicing. Profils : Desktop / Full / Security (opt-in).
Partitionnement : auto, manuel, ext4, Btrfs, LUKS, swap. UEFI + BIOS supportés.
Après reboot : même bureau que le live (post-install rejoue configs + skel).
