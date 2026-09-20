#!/usr/bin/env python3
"""ArchRicing Welcome — 1er boot uniquement. Mouse-first, fermable, jamais bloquant."""
import tkinter as tk
from tkinter import ttk
import os
root = tk.Tk(); root.title("Welcome to ArchRicing"); root.geometry("620x440")
ttk.Label(root, text="Welcome to ArchRicing", font=("Sans", 18, "bold")).pack(pady=12)
ttk.Label(root, text="A beautiful Arch Linux experience.\nFloating desktop • Mouse-first • No tiling", justify="center").pack()
for label in ("Appearance", "Wallpaper", "Theme", "Dock", "Terminal", "Browser", "Updates", "Security Toolkit (opt-in)", "Documentation"):
    ttk.Label(root, text="• " + label).pack(anchor="w", padx=60)
def close():
    try: os.remove(os.path.expanduser("~/.config/archricing-first-run"))
    except FileNotFoundError: pass
    try: os.remove(os.path.expanduser("~/.config/autostart/archricing-welcome.desktop"))
    except FileNotFoundError: pass
    root.destroy()
ttk.Button(root, text="Start using ArchRicing", command=close).pack(pady=20)
root.mainloop()
