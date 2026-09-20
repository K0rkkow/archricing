#!/usr/bin/env bash
# tests/test-qemu.sh — boot UEFI/BIOS, vérifie affichage/souris/réseau. Usage: ./tests/test-qemu.sh [uefi|bios]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-uefi}"
ISO=$(ls -t "$ROOT"/out/archricing-*.iso 2>/dev/null | head -n1 || echo "")
[[ -n "$ISO" ]] || { echo "Build d'abord: ./scripts/build-iso.sh"; exit 1; }
QEMU_IMG="/tmp/archricing-test.qcow2"
qemu-img create -f qcow2 "$QEMU_IMG" 20G >/dev/null
if [[ "$MODE" == uefi ]]; then
  OVMF="/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
  [[ -f "$OVMF" ]] || OVMF="/usr/share/OVMF/OVMF_CODE_4M.fd"
  [[ -f "$OVMF" ]] || { echo "ERREUR: OVMF introuvable (pacman -S edk2-ovmf)"; exit 1; }
  qemu-system-x86_64 -enable-kvm -m 4G -smp 2 -cpu host \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF" \
    -cdrom "$ISO" -drive file="$QEMU_IMG",format=qcow2,if=virtio \
    -device virtio-vga-gl -display gtk,gl=on -usb -device usb-tablet \
    -nic user,model=virtio-net-pci -device intel-hda -device hda-duplex
else
  qemu-system-x86_64 -enable-kvm -m 4G -smp 2 -cpu host \
    -cdrom "$ISO" -drive file="$QEMU_IMG",format=qcow2,if=virtio -boot d \
    -vga virtio -display gtk -usb -device usb-tablet \
    -nic user,model=virtio-net-pci -device intel-hda -device hda-duplex
fi
