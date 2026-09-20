#!/usr/bin/env python3
"""ArchRicing Software — GUI pacman/AUR (recherche/install/supprime/update). Backend pacman, rien réinventé."""
import subprocess, tkinter as tk
from tkinter import ttk, messagebox
def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)
root = tk.Tk(); root.title("ArchRicing Software"); root.geometry("680x480")
q = tk.StringVar()
ttk.Entry(root, textvariable=q, width=50).pack(pady=8)
lst = tk.Text(root, height=18); lst.pack(fill="both", expand=True, padx=10)
def search():
    r = run(f"pacman -Ss {q.get()}")
    lst.delete("1.0", "end"); lst.insert("end", r.stdout[:8000] or "Aucun résultat")
def install():
    pkg = q.get().strip()
    if messagebox.askyesno("Installer", f"Installer {pkg} via pacman ?"):
        r = run(f"pkexec pacman -S --needed {pkg}")
        messagebox.showinfo("Résultat", r.stdout[-1000:] or r.stderr[-1000:])
def update():
    r = run("pkexec pacman -Syu")
    messagebox.showinfo("Updates", r.stdout[-2000:])
for txt, fn in (("Rechercher", search), ("Installer", install), ("Tout mettre à jour", update)):
    ttk.Button(root, text=txt, command=fn).pack(side="left", padx=8, pady=8)
root.mainloop()
