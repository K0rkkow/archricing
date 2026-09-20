#!/usr/bin/env python3
"""ArchRicing Updates — affiche nb/taille/liste/progression. Jamais de MAJ sans clic."""
import subprocess, tkinter as tk
from tkinter import ttk
def out(cmd): return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout
root = tk.Tk(); root.title("ArchRicing Updates"); root.geometry("640x440")
ttk.Label(root, text="Updates available", font=("Sans", 14, "bold")).pack(pady=8)
txt = tk.Text(root); txt.pack(fill="both", expand=True, padx=10)
txt.insert("end", out("checkupdates 2>/dev/null || pacman -Qu 2>/dev/null || echo 'À jour ou checkupdates indisponible (live).'"))
ttk.Button(root, text="Update", command=lambda: subprocess.Popen(["pkexec", "pacman", "-Syu"])).pack(pady=10)
root.mainloop()
