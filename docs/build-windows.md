# BUILDING ARCHRICING FROM WINDOWS

> Tu es sur Windows : **ne build jamais l'ISO ici**. L'ISO se construit
> uniquement sur Arch Linux (mkarchiso + pacman + root + Linux).
> Deux chemins simples : **WSL2** (rapide) ou **VM Arch** (fidèle).

## Option A — WSL2 Arch (recommandé pour itérer)

```powershell
wsl --install
# Redémarre, puis dans Microsoft Store (ou : archlinux-wsl) installe "ArchWSL",
# ou importe un rootfs Arch : wsl --import Arch C:\WSL\Arch archlinux-bootstrap-x86_64.tar.gz
wsl -d Arch
```

Dans WSL Arch :

```bash
pacman -Syu --needed base-devel archiso git edk2-ovmf qemu-desktop shellcheck python
git clone https://github.com/K0rkkow/archricing ~/archricing
cd ~/archricing
git update-index --chmod=+x scripts/*.sh scripts/archricing iso/*.sh iso/airootfs/root/customize_airootfs.sh tests/*.sh
./tests/check-tree.sh
./tests/validate-packages.sh
sudo ./scripts/build-iso.sh
# -> out/archricing-*.iso + out/SHA256SUMS
```

Note : le test QEMU graphique (`./tests/test-qemu.sh uefi`) exige KVM ;
sous WSL2 il peut échouer (pas de /dev/kvm) — dans ce cas passe à l'option B
pour le boot test, ou teste l'ISO depuis Windows avec Hyper-V/VirtualBox (UEFI activé).

## Option B — VM Arch Linux (build + boot + install fidèles)

1. Installe VirtualBox/VMware/Hyper-V, crée une VM Arch (4 CPU, 8 Go RAM, 60 Go disque, UEFI activé).
2. Installe Arch (iso officielle), puis dans la VM :
```bash
sudo pacman -Syu --needed base-devel archiso git edk2-ovmf qemu-desktop shellcheck python
git clone https://github.com/K0rkkow/archricing ~/archricing
cd ~/archricing
./tests/check-tree.sh && ./tests/validate-packages.sh
sudo ./scripts/build-iso.sh
./tests/test-qemu.sh uefi   # KVM disponible dans la VM si virtualisation imbriquée aktivée
```

## Rappel honnêteté

- `tests/check-tree.sh` passe sous **Git Bash** (`bash tests/check-tree.sh`) :
  il ne valide que la structure/syntaxe, jamais le boot ni pacman.
- Ne jamais annoncer une ISO "testée" sans log `mkarchiso` + photo/menu de boot
  + `archricing diagnose` issus d'un vrai environnement Linux.
- Premier build : `./scripts/build-iso.sh` (en root, sur Arch), rien d'autre.
