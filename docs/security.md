# Security — toolkit OPT-IN, usage légal uniquement

Les outils de `packages/security/security-packages.txt` sont **disponibles, jamais exécutés auto**.
Aucun scan/reconnaissance au boot, à l'install ou en tâche de fond.

**Règle d'or : n'utilisez ces outils que sur des systèmes et environnements
pour lesquels vous disposez d'une autorisation explicite.**
Usage non autorisé = illégal (intrusion, interception, etc.).

Installation (avec avertissement GUI) : ArchRicing Settings → Security Toolkit,
ou `sudo pacman -S --needed $(grep -vE '^\s*(#|$)' packages/security/security-packages.txt | awk '{print $1}')`
puis AUR au cas par cas. VPN/privacy : préférez `wireguard-tools`/`openvpn`/`firefox`
si les paquets AUR (mullvad, librewolf) sont indisponibles.
