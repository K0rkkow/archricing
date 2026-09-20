# Éditions — NORMAL vs SECURITY

Deux choix dans Calamares, page **Choose your ArchRicing edition**
(`calamares/modules/packagechooser@edition.conf`, synchronisée avec
`packages/security/security-official.txt` — le build échoue en cas de divergence).

| | 🌸 NORMAL | 🛡️ SECURITY |
|---|---|---|
| Bureau | ArchRicing complet (dock flottant, panel, blur, wobbly, thèmes) | **Identique à Normal** |
| Paquets | core + desktop + personalization | Normal + `security-official.txt` (via Calamares) |
| AUR | — | `security-aur.txt` au 1er boot (`archricing-security-aur.service`, ignorer-et-journaliser si introuvable) |
| Menu KDE | standard | + catégorie **Security** (11 sous-catégories, `.desktop` générés depuis `security-tools.json`, binaires absents auto-désactivés par `validate-menu.sh`) |

Security n'est PAS un bureau différent et ne copie aucun branding tiers.
Personnalisation (**ArchRicing Experience** : thème, wallpaper, dock, panel,
transparence, blur, animations, wobbly, coins, icônes, curseur, terminal, fastfetch,
shell, starship, welcome, apps) : indépendante de l'édition, enregistrée dans
`/etc/archricing/install-profile.conf`, appliquée par `post-install.sh`.

**Légal :** outils réservés aux systèmes/environnements autorisés
(`docs/security.md`, `/etc/archricing/SECURITY-NOTICE.txt` sur édition Security).
Aucun scan ni exécution automatique, jamais.
