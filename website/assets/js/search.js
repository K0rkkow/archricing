/* search.js — client-side instant search over window.AR_SEARCH. No backend. */
(function () {
  "use strict";
  var DEPTH = parseInt(document.body.dataset.depth || "0", 10);
  function fixUrl(u) {
    if (/^https?:/.test(u)) return u;
    if (DEPTH === 2) return u.indexOf("docs/") === 0 ? u.slice(5) : "../" + u;
    if (DEPTH === 3) return u.indexOf("docs/") === 0 ? "../" + u.slice(5) : "../../" + u;
    return u;
  }
  var overlay = document.createElement("div");
  overlay.className = "search-pop"; overlay.id = "searchOverlay";
  overlay.setAttribute("role", "dialog"); overlay.setAttribute("aria-label", "Search");
  overlay.innerHTML = '<div class="search-box"><input id="searchInput" type="search" placeholder="SEARCH DOCS, COMMANDS, CATEGORIES…" aria-label="Search docs"><div class="search-res" id="searchResults"></div></div>';
  document.body.appendChild(overlay);
  var input = overlay.querySelector("#searchInput"), results = overlay.querySelector("#searchResults");
  function open() { overlay.classList.add("open"); input.value = ""; results.innerHTML = ""; setTimeout(function () { input.focus(); }, 30); }
  function close() { overlay.classList.remove("open"); }
  document.querySelectorAll("[data-search-open]").forEach(function (b) { b.addEventListener("click", open); });
  document.addEventListener("keydown", function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") { e.preventDefault(); overlay.classList.contains("open") ? close() : open(); }
    if (e.key === "Escape") close();
  });
  overlay.addEventListener("click", function (e) { if (e.target === overlay) close(); });
  input.addEventListener("input", function () {
    var q = input.value.trim().toLowerCase();
    results.innerHTML = "";
    if (q.length < 2 || !window.AR_SEARCH) return;
    var hits = window.AR_SEARCH.filter(function (p) {
      return (p.t + " " + p.s + " " + p.x).toLowerCase().indexOf(q) !== -1;
    }).slice(0, 14);
    hits.forEach(function (p) {
      var a = document.createElement("a");
      a.href = fixUrl(p.u);
      var strong = document.createElement("strong"); strong.textContent = p.t;
      var small = document.createElement("small"); small.textContent = p.s;
      a.appendChild(strong); a.appendChild(small);
      results.appendChild(a);
    });
    if (!hits.length) results.innerHTML = "<a><small>NO RESULTS FOR \"" + input.value.replace(/</g, "&lt;") + "\"</small></a>";
  });
})();
