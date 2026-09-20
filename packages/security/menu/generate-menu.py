#!/usr/bin/env python3
"""Génère le menu KDE Security (.desktop + .directory) depuis security-tools.json.
Idempotent : régénère tout à chaque appel. Exécuté à la main, au build
(iso/build.sh) et vérifié par tests/check-tree.sh (présence + validité Desktop Entry).
Les outils CLI sont lancés via archricing-terminal-exec (terminal choisi à l'install).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "security-tools.json")
APP_DIR = os.path.join(HERE, "applications")
DIR_DIR = os.path.join(HERE, "directories")

FALLBACK_ICON_CLI = "utilities-terminal"
FALLBACK_ICON_GUI = "applications-system"


def cat_token(sub):
    return "X-ArchRicing-" + sub.title().replace(" ", "").replace("&", "")


def main():
    with open(DATA, encoding="utf-8") as f:
        data = json.load(f)
    categories = data["categories"]
    tools = data["tools"]
    os.makedirs(APP_DIR, exist_ok=True)
    os.makedirs(DIR_DIR, exist_ok=True)

    # .directory : catégorie mère + 11 sous-catégories
    with open(os.path.join(DIR_DIR, "archricing-security.directory"), "w", encoding="utf-8") as f:
        f.write("[Desktop Entry]\nType=Directory\nName=Security\n"
                "Comment=ArchRicing security toolkit (legal use on authorized systems only)\n"
                "Icon=security-high\n")
    for sub, label in categories.items():
        with open(os.path.join(DIR_DIR, "archricing-%s.directory" % sub), "w", encoding="utf-8") as f:
            f.write("[Desktop Entry]\nType=Directory\nName=%s\n"
                    "Comment=ArchRicing Security — %s\nIcon=security-high\n" % (label, label))

    # .desktop : un par outil
    for t in tools:
        cats = ";".join(["X-ArchRicing-Security"] + [cat_token(c) for c in t["cats"]])
        if t["gui"]:
            run = t["bin"]
            term = "false"
            icon = t.get("icon", FALLBACK_ICON_GUI)
        else:
            run = "archricing-terminal-exec " + t["bin"]
            term = "false"  # le terminal est géré par le wrapper, pas par le .desktop
            icon = FALLBACK_ICON_CLI
        content = (
            "[Desktop Entry]\n"
            "Type=Application\n"
            "Name={name}\n"
            "GenericName=ArchRicing Security ({pkg})\n"
            "Comment={desc}\n"
            "Exec={run}\n"
            "Icon={icon}\n"
            "Terminal={term}\n"
            "Categories={cats};\n"
            "Keywords=security;archricing;\n"
            "NoDisplay=false\n"
            "X-ArchRicing-Package={pkg}\n"
            "X-ArchRicing-Repo={repo}\n".format(
                name=t["name"], pkg=t["pkg"], desc=t["desc"].replace("\n", " "),
                run=run, icon=icon, term=term, cats=cats, repo=t["repo"]))
        with open(os.path.join(APP_DIR, "archricing-%s.desktop" % t["id"]), "w", encoding="utf-8") as f:
            f.write(content)
    print("menu: %d applications, %d directories" % (len(tools), len(categories) + 1))


if __name__ == "__main__":
    sys.exit(main())
