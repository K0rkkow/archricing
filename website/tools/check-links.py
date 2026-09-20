#!/usr/bin/env python3
"""Verify the static site: every internal link/src resolves, relative paths only,
images exist, no framework/CDN/backend traces. Exit 1 on any failure.
Run: python3 website/tools/check-links.py"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HREF_RE = re.compile(r'''(?:href|src)="([^"]+)"''')
BANNED = ["react", "vue", "angular", "svelte", "astro", "tailwind", "bootstrap",
          "unpkg", "cdn.jsdelivr", "cdnjs", "googleapis", "gstatic",
          "node_modules", ".php", "<?php"]
fail = 0
pages = 0

for dirpath, _dirs, files in os.walk(ROOT):
    for fn in sorted(files):
        if not fn.endswith((".html", ".js", ".css")):
            continue
        full = os.path.join(dirpath, fn)
        rel = os.path.relpath(full, ROOT)
        with open(full, encoding="utf-8") as f:
            raw = f.read()
        if fn.endswith(".html"):
            pages += 1
            for m in HREF_RE.finditer(raw):
                link = m.group(1)
                if link.startswith(("https://", "http://", "mailto:", "#", "data:")):
                    if link.startswith(("https://", "http://")) and "K0rkkow/archricing" not in link \
                            and "w3.org" not in link and "github.com/fastfetch" not in link:
                        print("EXTERNAL (check): %s -> %s" % (rel, link))
                    continue
                if link.startswith("/"):
                    print("ABSOLUTE PATH (Pages-unsafe): %s -> %s" % (rel, link))
                    fail += 1
                    continue
                target = os.path.normpath(os.path.join(dirpath, link.split("#")[0]))
                if not os.path.exists(target):
                    print("BROKEN: %s -> %s" % (rel, link))
                    fail += 1
        low = raw.lower()
        for b in BANNED:
            if b in low:
                print("BANNED TRACE '%s' in %s" % (b, rel))
                fail += 1

# expected inventory
expected = ["index.html", "download.html", "changelog.html", "about.html",
            "favicon.svg", "README.md", "fr/index.html",
            "assets/css/main.css", "assets/css/docs.css",
            "assets/css/animations.css", "assets/css/responsive.css",
            "assets/js/main.js", "assets/js/themes.js",
            "assets/js/search.js", "assets/js/docs.js",
            "assets/img/logo.svg", "assets/data/search-index.js",
            "tools/build-index.py", "tools/check-links.py"]
for e in expected:
    if not os.path.isfile(os.path.join(ROOT, e)):
        print("MISSING: %s" % e)
        fail += 1
ndocs = len([f for f in os.listdir(os.path.join(ROOT, "docs")) if f.endswith(".html")])
print("docs pages: %d (want 24)" % ndocs)
if ndocs != 24:
    fail += 1
nwp = len([f for f in os.listdir(os.path.join(ROOT, "assets", "wallpapers")) if f.endswith(".svg")])
print("wallpaper previews: %d (want 9)" % nwp)
if nwp != 9:
    fail += 1
print("html pages scanned: %d" % pages)
print("RESULT: %s" % ("FAIL" if fail else "ALL LINKS OK"))
sys.exit(1 if fail else 0)
