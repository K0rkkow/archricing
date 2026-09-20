/* docs.js — sidebar + active page, TOC, pager, FAQ accordion. Vanilla. */
(function () {
  "use strict";
  var SIDEBAR = [
    ["GETTING STARTED", [["Introduction", "index.html"], ["Installation", "installation.html"], ["First boot", "first-boot.html"]]],
    ["ARCHRICING", [["Desktop", "desktop.html"], ["Themes", "themes.html"], ["Wallpapers", "wallpapers.html"], ["Dock", "dock.html"], ["Top panel", "panel.html"], ["Windows", "window-management.html"], ["Customization", "customization.html"]]],
    ["INSTALLER", [["Calamares", "installer.html"], ["Editions", "editions.html"], ["Normal", "editions.html#normal"], ["Security", "editions.html#security"], ["Installation options", "installation.html#options"]]],
    ["SOFTWARE", [["Software Center", "software-center.html"], ["Update Center", "update-center.html"], ["ArchRicing Settings", "settings.html"], ["ArchRicing CLI", "cli.html"], ["Terminal", "terminal.html"], ["Fastfetch", "fastfetch.html"]]],
    ["BUILD", [["Building the ISO", "building.html"], ["Architecture", "architecture.html"], ["Development", "development.html"], ["Troubleshooting", "troubleshooting.html"]]],
    ["COMMUNITY", [["Contributing", "contributing.html"], ["FAQ", "faq.html"], ["Changelog", "../changelog.html"]]]
  ];
  var PAGE = document.body.dataset.page || "";

  /* sidebar */
  var sb = document.getElementById("docSide");
  if (sb) {
    var html = "";
    SIDEBAR.forEach(function (g) {
      html += "<h3>" + g[0] + "</h3>";
      g[1].forEach(function (it) {
        var active = PAGE === it[1].split("#")[0] ? ' class="active" aria-current="page"' : "";
        html += '<a href="' + it[1] + '"' + active + ">" + it[0] + "</a>";
      });
    });
    sb.innerHTML = html;
  }

  /* TOC from h2/h3 */
  var toc = document.getElementById("docToc");
  if (toc) {
    var out = "";
    document.querySelectorAll(".doc h2,.doc h3").forEach(function (h, i) {
      if (!h.id) h.id = "sec-" + i;
      out += '<a class="' + (h.tagName === "H3" ? "l3" : "") + '" href="#' + h.id + '">' + h.textContent + "</a>";
    });
    toc.innerHTML = out;
  }

  /* pager */
  var pager = document.getElementById("docPager");
  if (pager) {
    var prev = document.body.dataset.prev, next = document.body.dataset.next;
    var pt = document.body.dataset.prevTitle || "PREV", nt = document.body.dataset.nextTitle || "NEXT";
    pager.innerHTML =
      (prev ? '<a class="px-btn" href="' + prev + '">← ' + pt + "</a>" : "<span></span>") +
      (next ? '<a class="px-btn" href="' + next + '">' + nt + " →</a>" : "<span></span>");
  }

  /* FAQ accordion */
  document.querySelectorAll(".faq-item").forEach(function (item) {
    var q = item.querySelector(".faq-q");
    if (!q) return;
    q.addEventListener("click", function () {
      var open = item.classList.toggle("open");
      q.setAttribute("aria-expanded", open ? "true" : "false");
    });
  });

  /* docs mobile sidebar */
  var t = document.getElementById("docSideToggle");
  if (t && sb) t.addEventListener("click", function () { sb.classList.toggle("open"); });
})();
