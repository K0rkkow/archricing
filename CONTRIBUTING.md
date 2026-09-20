# Contributing to ArchRicing

Merci de contribuer. Règles courtes et strictes :

1. **Design principles** (voir README) : pas de tiling par défaut, mouse-first,
   pas de raccourcis imposés, tout le visuel customisable graphiquement.
2. **Idempotence** : tout script doit pouvoir être relancé sans casser le système.
   Toujours sauvegarder avant d'écraser (`*.bak-YYYYMMDD-HHMMSS`).
3. **Pas de réseau automatique** : aucun scan, aucune télémétrie, aucun
   téléchargement silencieux. Le toolkit sécurité ne s'exécute jamais seul.
4. **Noms de paquets** : vérifier sur https://archlinux.org/packages/ avant tout PR.
   Les paquets AUR vont dans `packages/aur/` + doc d'alternative.
5. **Tests** : `shellcheck` propre + test QEMU documenté (`tests/`).

## Workflow

```bash
git checkout -b feat/mon-truc
# ... modifications ...
shellcheck scripts/*.sh iso/build.sh 2>/dev/null || bash -n scripts/*.sh
./tests/check-tree.sh
./tests/validate-packages.sh   # vérifie les listes contre pacman -Si (sur Arch)
git commit -m "feat(scope): description courte"
```

## Ce qu'on refuse

- config Hyprland/tiling imposée, Super+Q/W/1/2/3 obligatoire
- terminal opaque par défaut, KDE vanilla non thémé
- scripts qui écrasent sans backup, services inutiles en boucle
- outils sécurité lancés automatiquement
