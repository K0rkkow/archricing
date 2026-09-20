# Troubleshooting

| Symptôme | Cause probable | Fix |
|---|---|---|
| Blur scintille pendant wobble | Bug KWin #474196 (Wayland) | Wobbly → SUBTLE ou `archricing reset` ; fix partiel dès KWin 6.4 |
| Paquet "INCONNU" à la validation | Renommé ou passé AUR | Voir alternative en commentaire dans `packages/*` ; ex. `httpx`→`httprobe`, `librewolf-bin`→`firefox` |
| `latte-dock` introuvable/casse Plasma | Abandonné upstream | Utiliser le dock natif (déjà configuré) |
| NVIDIA + Wayland glitches | Driver `nouveau`/modeset | `pacman -S nvidia-open nvidia-utils egl-wayland`, reboot |
| Calamares ne voit pas le disque | VM NVMe/RAID | Passer en virtio/sata ou partitionnement manuel |
| Kitty opaque | Config écrasée | `archricing reset`, vérifier `background_opacity 0.72` |
| Diagnose | — | `archricing diagnose` (GPU/Wayland/KDE/audio/réseau/disque/mémoire) |
