# BUILDING ARCHRICING FROM WINDOWS

> Tu es sur Windows : **ne build jamais l'ISO ici**. L'ISO se construit
> avec archiso/mkarchiso dans un environnement Arch (natif ou conteneur).
> Trois chemins : **WSL2** (rapide), **VM Arch** (fidèle), ou **conteneur
> depuis une autre distro Linux** (`./build.sh` gère podman/docker tout seul).

## Option A — WSL2 Arch (recommandé pour itérer)

```powershell
wsl --install
# Redémarre, puis dans Microsoft Store (ou : archlinux-wsl) installe "ArchWSL",
# ou importe un rootfs Arch : wsl --import Arch C:\WSL\Arch archlinux-bootstrap-x86_64.tar.gz
wsl -d Arch
```

Dans WSL Arch :

```bash
pacman -Syu --needed base-devel git edk2-ovmf qemu-desktop shellcheck python
git clone https://github.com/K0rkkow/archricing ~/archricing
cd ~/archricing
./tests/check-tree.sh
./tests/validate-packages.sh
./build.sh
# -> out/archricing-*.iso + out/SHA256SUMS
```

Note : le test QEMU graphique (`./tests/test-qemu.sh uefi`) exige KVM ;
sous WSL2 il peut échouer (pas de /dev/kvm) — dans ce cas passe à l'option B
pour le boot test, ou teste l'ISO depuis Windows avec Hyper-V/VirtualBox (UEFI activé).

## Option B — VM Arch Linux (build + boot + install fidèles)

1. Installe VirtualBox/VMware/Hyper-V, crée une VM Arch (4 CPU, 8 Go RAM, 60 Go disque, UEFI activé).
2. Installe Arch (iso officielle), puis dans la VM :
```bash
sudo pacman -Syu --needed base-devel git edk2-ovmf qemu-desktop shellcheck python
git clone https://github.com/K0rkkow/archricing ~/archricing
cd ~/archricing
./tests/check-tree.sh && ./tests/validate-packages.sh
./build.sh
./tests/test-qemu.sh uefi   # KVM disponible dans la VM si virtualisation imbriquée aktivée
```

## Rappel honnêteté

- `tests/check-tree.sh` passe sous **Git Bash** (`bash tests/check-tree.sh`) :
  il ne valide que la structure/syntaxe, jamais le boot ni pacman.
- Ne jamais annoncer une ISO "testée" sans log `mkarchiso` + photo/menu de boot
  + `archricing diagnose` issus d'un vrai environnement Linux.
- Premier build : `./build.sh`, rien d'autre (sudo/conteneur gérés automatiquement).
  (`scripts/build-iso.sh` et `iso/build.sh` sont dépréciés : simples relais vers `./build.sh`.)

## Option C — Autre distro Linux (Fedora/Debian/Ubuntu, …)

Pas besoin d'installer Arch : `./build.sh` détecte l'absence d'Arch, utilise
podman (ou docker), monte le repo dans `/src` (relabel SELinux `:z`), installe
archiso dans un conteneur `archlinux:latest` et y lance le build. L'ISO et
`SHA256SUMS` retombent dans `out/` avec les bons propriétaires.
