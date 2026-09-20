# ArchRicing website — static, vanilla, Pages-ready

100% HTML5 + CSS3 + vanilla JavaScript. No framework, no backend, no build step.

## Open locally

```bash
git clone https://github.com/K0rkkow/archricing.git
cd archricing/website
# open index.html in a browser, or serve statically:
python3 -m http.server 8000
# -> http://localhost:8000
```

Everything works from `file://` too (no `fetch()`, no modules, no CDN).

## Publish on GitHub Pages

No workflow needed (branch deploy):

1. Repo → Settings → Pages → Source: **Deploy from a branch**.
2. Branch: `main`, folder: `/website`. Save.
3. Site live at `https://<owner>.github.io/archricing/`.

## Layout

- `index.html`, `download.html`, `changelog.html`, `about.html`, `fr/index.html`
- `docs/` — 24 documentation pages (EN)
- `assets/css/` — `main.css` (tokens + components), `docs.css`, `animations.css`, `responsive.css`
- `assets/js/` — `main.js` (grid, cursor, reveals, demos), `themes.js` (10 themes),
  `search.js` (client-side), `docs.js` (sidebar, TOC, pager, FAQ)
- `assets/img/logo.svg`, `favicon.svg` (original pixel brand)
- `assets/wallpapers/` — **copies** of `../../wallpapers/*.svg` for self-containment
  (re-sync by copying; they are CC-BY-SA-4.0 originals)
- `assets/data/search-index.js` — generated, do not hand-edit
- `tools/` — `build-index.py`, `check-links.py` (run, don't ship-edit)

## i18n

EN is primary (`/` pages + `docs/`). FR lives in `fr/` (homepage only — translation
in progress). Convention: same filename, `hreflang` switcher in the header.

## Regenerate / verify (needs python3 + bash only)

```bash
python3 website/tools/build-index.py   # rebuild assets/data/search-index.js
python3 website/tools/check-links.py   # every internal link resolves, no framework CDN
bash tests/check-tree.sh               # includes website smoke checks
```
