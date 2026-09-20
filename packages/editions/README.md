# ÉDITIONS ArchRicing — NORMAL vs SECURITY.
#
# NORMAL   = packages/core + packages/desktop + packages/personalization
#            (bureau ArchRicing complet, ricing inclus, sans outils security).
# SECURITY = NORMAL + packages/security/security-official.txt (via Calamares,
#            choix "SECURITY") + packages/security/security-aur.txt (au 1er boot
#            via archricing-security-aur.service) + catégorie "Security" dans KDE.
#
# Même bureau, mêmes thèmes, mêmes effets. Security n'est PAS un bureau différent.
# Le choix d'édition se fait dans Calamares : calamares/modules/packagechooser@edition.conf
# La personnalisation (theme/wallpaper/dock/...) se fait page "ArchRicing Experience"
# (calamares/custom-modules/archricing_experience/) et est enregistrée dans
# /etc/archricing/install-profile.conf, indépendante de l'édition.
