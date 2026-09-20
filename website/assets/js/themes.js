/* themes.js — 10 original ArchRicing site themes. Vanilla, localStorage. */
(function () {
  "use strict";
  var THEMES = ["pixel-night", "sakura", "aurora", "ocean", "midnight", "dream", "cyber", "minimal", "terminal-green", "rose-dusk"];
  var LABELS = {
    "pixel-night": "Pixel Night", "sakura": "Sakura", "aurora": "Aurora", "ocean": "Ocean",
    "midnight": "Midnight", "dream": "Dream", "cyber": "Cyber", "minimal": "Minimal",
    "terminal-green": "Terminal Green", "rose-dusk": "Rose Dusk"
  };
  function current() { return document.documentElement.dataset.siteTheme || "pixel-night"; }
  function apply(name) {
    if (THEMES.indexOf(name) === -1) name = "pixel-night";
    document.documentElement.dataset.siteTheme = name;
    try { localStorage.setItem("ar-site-theme", name); } catch (e) {}
    document.documentElement.dispatchEvent(new Event("ar-theme"));
    document.querySelectorAll("[data-theme-swatches] button").forEach(function (b) {
      if (b.dataset.themeSet === name) b.setAttribute("aria-pressed", "true");
      else b.removeAttribute("aria-pressed");
    });
    var label = document.getElementById("themeName");
    if (label) label.textContent = LABELS[name];
  }
  try {
    var saved = localStorage.getItem("ar-site-theme");
    if (saved && THEMES.indexOf(saved) !== -1) document.documentElement.dataset.siteTheme = saved;
  } catch (e) {}
  document.querySelectorAll("[data-theme-swatches]").forEach(function (box) {
    THEMES.forEach(function (name) {
      var b = document.createElement("button");
      b.className = "swatch"; b.dataset.themeSet = name; b.title = LABELS[name];
      b.setAttribute("aria-label", "Use theme " + LABELS[name]);
      b.style.cssText = "width:34px;height:34px;cursor:pointer;border:3px solid var(--line);background:var(--panel)";
      b.innerHTML = '<span style="display:block;height:100%;background:linear-gradient(135deg,var(--cyan) 33%,var(--violet) 33% 66%,var(--pink) 66%)"></span>';
      /* preview in the theme's own colors is impossible pre-switch; keep neutral chip */
      b.addEventListener("click", function () { apply(name); });
      box.appendChild(b);
    });
    var names = document.createElement("div");
    names.style.cssText = "width:100%;font-family:var(--font-mono);font-size:.8rem;color:var(--mut);margin-top:.4rem";
    names.innerHTML = 'Active: <strong id="themeName">' + LABELS[current()] + "</strong>";
    box.appendChild(names);
  });
  var toggle = document.getElementById("themeToggle");
  if (toggle) toggle.addEventListener("click", function () {
    var i = THEMES.indexOf(current());
    apply(THEMES[(i + 1) % THEMES.length]);
  });
  window.AR_THEMES = { list: THEMES, apply: apply, current: current };
})();
