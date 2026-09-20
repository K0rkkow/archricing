#!/usr/bin/env python3
# archricing_experience/main.py — ViewStep + Job Calamares (PythonQt).
# Page "ArchRicing Experience" : personnalisation graphique indépendante de l'édition.
# Les valeurs par défaut viennent de configs/install-profile.default.conf.
# NOT VERIFIED : à tester sur un vrai Calamares (PythonQt API).

PROFILE_KEYS = [
    ("THEME", ["sakura", "aurora", "ocean", "midnight", "dream", "cyber", "minimal"]),
    ("DOCK", ["floating", "classic", "none"]),
    ("TOP_PANEL", ["on", "off"]),
    ("TRANSPARENCY", ["on", "off"]),
    ("BLUR", ["on", "off"]),
    ("ANIMATIONS", ["on", "off", "performance"]),
    ("WOBBLY", ["off", "subtle", "normal", "playful"]),
    ("ROUNDED", ["on", "off"]),
    ("ICONS", ["Papirus-Dark", "Papirus-Light", "breeze"]),
    ("CURSOR", ["Bibata-Modern-Ice", "Bibata-Modern-Classic", "breeze"]),
    ("TERMINAL", ["kitty", "konsole", "system"]),
    ("FASTFETCH", ["on", "off"]),
    ("SHELL", ["zsh", "bash"]),
    ("STARSHIP", ["on", "off"]),
    ("WELCOME", ["on", "off"]),
    ("SETTINGS_APP", ["installed", "skipped"]),
    ("SOFTWARE_APP", ["installed", "skipped"]),
    ("UPDATE_APP", ["installed", "skipped"]),
]

DEFAULTS = {
    "THEME": "sakura", "DOCK": "floating", "TOP_PANEL": "on",
    "TRANSPARENCY": "on", "BLUR": "on", "ANIMATIONS": "on",
    "WOBBLY": "normal", "ROUNDED": "on",
    "ICONS": "Papirus-Dark", "CURSOR": "Bibata-Modern-Ice",
    "TERMINAL": "kitty", "FASTFETCH": "on", "SHELL": "zsh", "STARSHIP": "on",
    "WELCOME": "on", "SETTINGS_APP": "installed",
    "SOFTWARE_APP": "installed", "UPDATE_APP": "installed",
}

WALLPAPER_FOR_THEME = {
    "sakura": "archricing-sakura.svg", "aurora": "archricing-aurora.svg",
    "ocean": "archricing-ocean.svg", "midnight": "archricing-midnight.svg",
    "dream": "archricing-dream.svg", "cyber": "archricing-cyber.svg",
    "minimal": "archricing-minimal.svg",
}

try:
    import libcalamares
    from PyQt5.QtWidgets import QWidget, QVBoxLayout, QFormLayout, QComboBox, QLabel
    HAS_QT = True
except ImportError:
    HAS_QT = False


class ArchRicingExperienceViewStep:
    """ViewStep : un QComboBox par option. Aucune option n'installe d'outil
    Security individuellement (SECURITY = suite complète, automatique)."""

    def __init__(self):
        self.widget = None
        self.combos = {}
        self._values = dict(DEFAULTS)

    def prettyName(self):
        return "ArchRicing Experience"

    def widget(self):
        if not HAS_QT:
            return None
        w = QWidget()
        layout = QVBoxLayout(w)
        layout.addWidget(QLabel("Customize your ArchRicing experience. Applies to NORMAL and SECURITY alike."))
        form = QFormLayout()
        for key, choices in PROFILE_KEYS:
            combo = QComboBox()
            combo.addItems(choices)
            combo.setCurrentText(DEFAULTS[key])
            combo.currentTextChanged.connect(lambda v, k=key: self._values.__setitem__(k, v))
            self.combos[key] = combo
            form.addRow(key, combo)
        layout.addLayout(form)
        self.widget = w
        return w

    def next(self):
        return None

    def jobs(self):
        return []

    def onLeave(self):
        try:
            import libcalamares
            for k, v in self._values.items():
                libcalamares.globalstorage.insert("archricing_" + k, v)
            libcalamares.globalstorage.insert(
                "archricing_WALLPAPER",
                WALLPAPER_FOR_THEME.get(self._values.get("THEME", "sakura"),
                                       "archricing-sakura.svg"))
        except Exception:
            pass
        return True


class ArchRicingExperienceJob:
    """Job (exec) : persiste le profil dans /etc/archricing/install-profile.conf
    de la cible + mémorise l'édition choisie (packagechooser@edition)."""

    def prettyName(self):
        return "Saving ArchRicing profile"

    def exec(self):
        import os
        try:
            import libcalamares
            gs = libcalamares.globalstorage
            root = gs.value("rootMountPoint")
            values = {}
            for key, _ in PROFILE_KEYS:
                values[key] = gs.value("archricing_" + key) or DEFAULTS[key]
            values["WALLPAPER"] = gs.value("archricing_WALLPAPER") or \
                WALLPAPER_FOR_THEME.get(values.get("THEME", "sakura"))
            pkgs = gs.value("packages") or []
            values["EDITION"] = "security" if any(
                p in ("nmap", "ghidra", "hashcat") for p in pkgs) else "normal"
        except Exception:
            import copy
            root, values = "/", copy.deepcopy(DEFAULTS)
            values["WALLPAPER"] = WALLPAPER_FOR_THEME["sakura"]
            values["EDITION"] = "normal"
        confdir = os.path.join(root, "etc/archricing")
        os.makedirs(confdir, exist_ok=True)
        with open(os.path.join(confdir, "install-profile.conf"), "w") as f:
            f.write("# Généré par Calamares (ArchRicing Experience). Lu par ArchRicing Settings.\n")
            for k in ["EDITION"] + [k for k, _ in PROFILE_KEYS] + ["WALLPAPER"]:
                f.write("{}={}\n".format(k, values.get(k, "")))
        return None


def run():
    """Point d'entrée job (Calamares appelle run() pour les modules job)."""
    return ArchRicingExperienceJob().exec()
