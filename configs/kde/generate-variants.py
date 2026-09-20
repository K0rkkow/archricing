#!/usr/bin/env python3
"""Génère les variantes de layout Plasma (dock × top panel) depuis la référence :
configs/kde/plasma-org.kde.plasma.desktop-appletsrc ([1]=top panel, [2]=dock flottant).
Sortie : configs/kde/variants/plasma-<dock>-<panel>.conf
  dock  : floating (défaut) | classic (non flottant, épais) | none (pas de dock)
  panel : panel (top panel) | nopanel
Règle : DOCK=none + TOP_PANEL=off est invalide (aucun launcher) -> repli none+panel.
Idempotent. Exécuté à la main, au build et vérifié par check-tree (6 fichiers)."""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "plasma-org.kde.plasma.desktop-appletsrc")
OUT = os.path.join(HERE, "variants")

PANEL_BLOCK = "Containments][1]"
DOCK_BLOCK = "Containments][2]"


def split_blocks(text):
    """Découpe en (préambule, bloc panel, bloc dock)."""
    i1 = text.find("[Containments][1]")
    i2 = text.find("[Containments][2]")
    if i1 < 0 or i2 < 0 or i2 < i1:
        raise SystemExit("bloc panel/dock introuvable dans la référence")
    return text[:i1], text[i1:i2], text[i2:]


def dock_classic(dock):
    dock = dock.replace("floating=true", "floating=false")
    dock = re.sub(r"^thickness=\d+", "thickness=48", dock, flags=re.M)
    return dock


def main():
    with open(SRC, encoding="utf-8") as f:
        text = f.read()
    pre, panel, dock = split_blocks(text)
    os.makedirs(OUT, exist_ok=True)
    variants = {
        "floating-panel": (dock, panel),
        "classic-panel": (dock_classic(dock), panel),
        "none-panel": ("", panel),
        "floating-nopanel": (dock, ""),
        "classic-nopanel": (dock_classic(dock), ""),
        "none-nopanel": ("", panel),  # repli documenté : jamais sans launcher
    }
    for name, (d, p) in variants.items():
        with open(os.path.join(OUT, "plasma-%s.conf" % name), "w", encoding="utf-8") as f:
            f.write("# Variante %s — générée, ne pas éditer à la main.\n" % name)
            f.write(pre + p + d)
    print("variants: %d fichiers" % len(variants))


if __name__ == "__main__":
    sys.exit(main())
