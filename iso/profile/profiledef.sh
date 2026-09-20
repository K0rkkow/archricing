#!/usr/bin/env bash
# ArchRicing archiso profiledef — compatible archiso >= 80 (mkarchiso -v).
# Usage: mkarchiso -v -w work -o out iso/profile
iso_name="archricing"
iso_label="ARCHRICING"
iso_publisher="ArchRicing Project <https://github.com/K0rkkow/archricing>"
iso_application="ArchRicing live/installation media"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
           'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers.d"]="0:0:750"
  ["/usr/local/bin/archricing"]="0:0:755"
  ["/usr/local/bin/archricing-postinstall"]="0:0:755"
  ["/usr/local/bin/archricing-settings"]="0:0:755"
  ["/usr/local/bin/archricing-welcome"]="0:0:755"
  ["/root/customize_airootfs.sh"]="0:0:755"
)
