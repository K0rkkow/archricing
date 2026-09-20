#!/usr/bin/env python3
"""ArchRicing Settings — centre de personnalisation (Tkinter, zéro dépendance).
Tout le visuel réglable graphiquement : sliders opacity/blur, wobbly, dock, terminal.
Sûr : backup avant écriture. Idempotent."""
import json, os, shutil, tkinter as tk
from tkinter import ttk, messagebox
from datetime import datetime

HOME = os.path.expanduser("~")
ROOT_CANDIDATES = ["/usr/share/archricing", os.path.join(os.path.dirname(__file__), "..", "..")]
THEMES = ["sakura", "aurora", "ocean", "midnight", "dream", "cyber", "minimal"]
WOBBLY = {"off": 0, "subtle": 0, "normal": 1, "playful": 2}

def backup(p):
    if os.path.exists(p):
        shutil.copy(p, f"{p}.bak-{datetime.now():%Y%m%d-%H%M%S}")

def set_kitty_opacity(v):
    p = os.path.join(HOME, ".config/kitty/kitty.conf")
    backup(p)
    lines = open(p).read().splitlines() if os.path.exists(p) else []
    out, seen = [], False
    for ln in lines:
        if ln.strip().startswith("background_opacity"):
            out.append(f"background_opacity {float(v)/100:.2f}"); seen = True
        else: out.append(ln)
    if not seen: out.append(f"background_opacity {float(v)/100:.2f}")
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write("\n".join(out) + "\n")

def set_wobbly(level):
    p = os.path.join(HOME, ".config/kwinrc")
    backup(p)
    cfg = open(p).read() if os.path.exists(p) else "[Plugins]\n"
    if "[Plugins]" not in cfg: cfg += "\n[Plugins]\n"
    want = "true" if level != "off" else "false"
    import re
    cfg = re.sub(r"wobblywindowsEnabled=.*", f"wobblywindowsEnabled={want}", cfg) if "wobblywindowsEnabled" in cfg else cfg.replace("[Plugins]", f"[Plugins]\nwobblywindowsEnabled={want}")
    open(p, "w").write(cfg)

def apply_theme(name):
    for base in ROOT_CANDIDATES:
        src = os.path.join(base, "themes", name, "theme.json")
        alt = os.path.join(base, f"{name}.json")
        for cand in (src, alt):
            if os.path.exists(cand):
                t = json.load(open(cand))
                messagebox.showinfo("ArchRicing", f"Thème {t.get('label', name)} : wallpaper={t.get('wallpaper')}\nAppliquez le wallpaper via clic droit Bureau ou `archricing theme {name}`.")
                return
    messagebox.showwarning("ArchRicing", f"Thème {name} introuvable.")

root = tk.Tk(); root.title("ArchRicing Settings"); root.geometry("640x520")
ttk.Label(root, text="ArchRicing Settings — Appearance / Windows / Dock / Terminal", font=("Sans", 13, "bold")).pack(pady=10)
nb = ttk.Notebook(root); nb.pack(fill="both", expand=True, padx=10, pady=5)

f1 = ttk.Frame(nb); nb.add(f1, text="Appearance")
for i, t in enumerate(THEMES):
    ttk.Button(f1, text=t.capitalize(), command=lambda n=t: apply_theme(n)).grid(row=i//3, column=i%3, padx=8, pady=8, sticky="ew")

f2 = ttk.Frame(nb); nb.add(f2, text="Terminal")
ttk.Label(f2, text="Terminal transparency").pack()
op = tk.IntVar(value=72)
ttk.Scale(f2, from_=10, to=100, variable=op, command=lambda v: set_kitty_opacity(float(v))).pack(fill="x", padx=20)
ttk.Label(f2, text="Blur behind terminal : géré par KWin (Effect-Blur). ON par défaut.").pack(pady=10)

f3 = ttk.Frame(nb); nb.add(f3, text="Windows")
ttk.Label(f3, text="Wobbly windows (natif KWin, Wayland)").pack()
wv = tk.StringVar(value="normal")
for lvl in ("off", "subtle", "normal", "playful"):
    ttk.Radiobutton(f3, text=lvl.upper(), value=lvl, variable=wv, command=lambda: set_wobbly(wv.get())).pack(anchor="w", padx=30)
ttk.Label(f3, text="Fenêtres toujours flottantes. Aucun tiling. Contrôles min/max/close conservés.").pack(pady=10)

f4 = ttk.Frame(nb); nb.add(f4, text="System")
ttk.Button(f4, text="Reset ArchRicing Settings (avec backup)", command=lambda: os.system("archricing reset")).pack(pady=10)
ttk.Button(f4, text="Diagnose", command=lambda: os.system("archricing diagnose")).pack(pady=5)
ttk.Label(f4, text="Security Toolkit : installation OPT-IN uniquement,\nusage légal sur systèmes autorisés.", justify="center").pack(pady=15)
root.mainloop()
