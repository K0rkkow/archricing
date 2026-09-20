#!/usr/bin/env bash
# scripts/hardware-detect.sh — Intel/AMD/NVIDIA, laptop/VM/desktop. Sortie lisible + flags.
set -uo pipefail
say(){ printf '%s\n' "$*"; }
GPU="unknown"; CPU="unknown"; CHASSIS="desktop"; VM="none"
CPUINFO="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null || echo unknown)"
case "$CPUINFO" in *Intel*) CPU="intel";; *AMD*) CPU="amd";; esac
if lspci 2>/dev/null | grep -qi nvidia; then GPU="nvidia";
elif lspci 2>/dev/null | grep -qi 'amd.*vga\|radeon\|amdgpu' -i; then GPU="amd";
elif lspci 2>/dev/null | grep -qi intel; then GPU="intel"; fi
[[ -d /sys/class/power_supply/BAT* ]] 2>/dev/null || ls /sys/class/power_supply/ 2>/dev/null | grep -qi bat && CHASSIS="laptop"
systemd-detect-virt 2>/dev/null | grep -qv none && { VM="$(systemd-detect-virt)"; CHASSIS="vm"; }
say "CPU=$CPU GPU=$GPU CHASSIS=$CHASSIS VM=$VM"
say "RECOMMEND_GPU_DRIVER=$([ "$GPU" = nvidia ] && echo 'nvidia-open + nvidia-utils + egl-wayland' || echo 'mesa + vulkan-icd-loader')"
say "RECOMMEND_HIDPI=$([ "$CHASSIS" = laptop ] && echo 'auto-scale 125-150% via Settings>Display' || echo '100%')"
