/* main.js — pixel grid, pixel cursor, reveals, counters, menus, copy, demos. Vanilla only. */
(function () {
  "use strict";
  var reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var fine = window.matchMedia("(pointer: fine)").matches;

  /* ---- pixel grid canvas: cheap, static + cursor ripple ---- */
  (function grid() {
    var cv = document.getElementById("pxgrid");
    if (!cv) return;
    var ctx = cv.getContext("2d"), mx = -9999, my = -9999, running = false, t = 0;
    function css(v) { return getComputedStyle(document.documentElement).getPropertyValue(v).trim(); }
    function size() { cv.width = innerWidth; cv.height = innerHeight; draw(0); }
    function draw() {
      var step = 34, w = cv.width, h = cv.height;
      ctx.clearRect(0, 0, w, h);
      var base = css("--line") || "#2b2b38", hot = css("--accent") || "#00e5ff";
      ctx.fillStyle = base;
      for (var y = step / 2; y < h; y += step) {
        for (var x = step / 2; x < w; x += step) {
          var dx = x - mx, dy = y - my, d = Math.sqrt(dx * dx + dy * dy);
          if (d < 130) {
            ctx.fillStyle = hot; ctx.globalAlpha = 1 - d / 130;
            ctx.fillRect(x - 2, y - 2, 5, 5);
            ctx.globalAlpha = 1; ctx.fillStyle = base;
          } else {
            ctx.globalAlpha = 0.5; ctx.fillRect(x - 1, y - 1, 2, 2); ctx.globalAlpha = 1;
          }
        }
      }
    }
    function loop() {
      if (!running) return;
      t++;
      if (t % 3 === 0) draw();
      if (t > 40 && mx < -1000) { running = false; return; }
      requestAnimationFrame(loop);
    }
    function kick() { if (reduced) { size(); return; } if (!running) { running = true; t = 0; requestAnimationFrame(loop); } }
    addEventListener("resize", size);
    addEventListener("pointermove", function (e) { mx = e.clientX; my = e.clientY; kick(); }, { passive: true });
    document.addEventListener("visibilitychange", function () { if (document.hidden) running = false; });
    document.documentElement.addEventListener("ar-theme", size);
    size();
  })();

  /* ---- pixel cursor follower (fine pointers only, motion-safe) ---- */
  (function cursor() {
    if (reduced || !fine) return;
    var c = document.createElement("div");
    c.setAttribute("aria-hidden", "true");
    c.style.cssText = "position:fixed;z-index:500;pointer-events:none;width:10px;height:10px;background:var(--accent);box-shadow:0 0 12px var(--accent);left:0;top:0;image-rendering:pixelated";
    document.body.appendChild(c);
    var x = 0, y = 0, tx = 0, ty = 0;
    addEventListener("pointermove", function (e) { tx = e.clientX; ty = e.clientY; }, { passive: true });
    (function follow() {
      x += (tx - x) * 0.35; y += (ty - y) * 0.35;
      c.style.transform = "translate(" + (x - 5) + "px," + (y - 5) + "px)";
      requestAnimationFrame(follow);
    })();
    document.querySelectorAll("a,.px-btn,button").forEach(function (b) {
      b.addEventListener("pointerenter", function () { c.style.transform += ""; c.style.width = "16px"; c.style.height = "16px"; });
      b.addEventListener("pointerleave", function () { c.style.width = "10px"; c.style.height = "10px"; });
    });
  })();

  /* ---- scroll reveals ---- */
  (function reveals() {
    if (reduced || !("IntersectionObserver" in window)) {
      document.querySelectorAll(".reveal").forEach(function (e) { e.classList.add("in"); });
      return;
    }
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); } });
    }, { threshold: 0.12 });
    document.querySelectorAll(".reveal").forEach(function (e) { io.observe(e); });
  })();

  /* ---- counters ---- */
  (function counters() {
    document.querySelectorAll("[data-count]").forEach(function (e) {
      var target = parseInt(e.dataset.count, 10) || 0;
      if (reduced) { e.textContent = target; return; }
      var v = 0, step = Math.max(1, Math.round(target / 40));
      var iv = setInterval(function () {
        v += step; if (v >= target) { v = target; clearInterval(iv); }
        e.textContent = v;
      }, 40);
    });
  })();

  /* ---- mobile menu ---- */
  var burger = document.getElementById("menuBtn"), links = document.getElementById("navLinks");
  if (burger && links) burger.addEventListener("click", function () {
    var open = links.classList.toggle("open");
    burger.setAttribute("aria-expanded", open ? "true" : "false");
  });

  /* ---- copy buttons ---- */
  document.querySelectorAll("pre[data-copy],.term").forEach(function (box) {
    if (box.querySelector(".copy-btn")) return;
    var b = document.createElement("button");
    b.className = "px-iconbtn copy-btn"; b.textContent = "COPY"; b.setAttribute("aria-label", "Copy code");
    b.addEventListener("click", function () {
      var code = box.querySelector("code") || box;
      navigator.clipboard.writeText(code.innerText).then(function () {
        b.textContent = "OK"; setTimeout(function () { b.textContent = "COPY"; }, 1400);
      });
    });
    box.style.position = "relative"; box.appendChild(b);
  });

  /* ---- desktop mockup tabs ---- */
  document.querySelectorAll("[data-mock-tabs]").forEach(function (tabs) {
    var mock = document.getElementById(tabs.dataset.mockTabs);
    var note = document.getElementById(tabs.dataset.mockNote);
    var INFO = {
      desktop: "Full ArchRicing look: wallpaper, top panel, floating windows, dock.",
      dock: "Bottom-center floating dock: launcher, apps, settings, monitor.",
      panel: "Slim top bar: clock, network, sound, battery, session.",
      windows: "Floating only. Drag, resize, minimize, maximize — with the mouse.",
      themes: "One click restyles wallpaper, colors, terminal, dock and panels."
    };
    tabs.querySelectorAll("button").forEach(function (btn) {
      btn.addEventListener("click", function () {
        tabs.querySelectorAll("button").forEach(function (o) { o.removeAttribute("aria-pressed"); });
        btn.setAttribute("aria-pressed", "true");
        if (mock) mock.dataset.view = btn.dataset.view;
        if (note) note.textContent = INFO[btn.dataset.view] || "";
      });
    });
  });

  /* ---- wobbly demo: windows lean toward the cursor (site animation only) ---- */
  (function wobble() {
    var zone = document.getElementById("wobbleZone");
    if (!zone || reduced || !fine) return;
    var wins = zone.querySelectorAll(".wobble-win");
    zone.addEventListener("pointermove", function (e) {
      var r = zone.getBoundingClientRect();
      var nx = (e.clientX - r.left) / r.width - 0.5, ny = (e.clientY - r.top) / r.height - 0.5;
      wins.forEach(function (w, i) {
        var f = (i + 1) * 6;
        w.style.transform = "rotate(" + (nx * f) + "deg) translate(" + (nx * f * 2) + "px," + (ny * f * 2) + "px)";
      });
    });
    zone.addEventListener("pointerleave", function () {
      wins.forEach(function (w) { w.style.transform = ""; });
    });
  })();

  /* ---- terminal typing demo ---- */
  (function typing() {
    var t = document.getElementById("termType");
    if (!t || reduced) return;
    var full = t.dataset.text || t.textContent;
    t.textContent = "";
    var i = 0;
    var iv = setInterval(function () {
      t.textContent = full.slice(0, ++i);
      if (i >= full.length) clearInterval(iv);
    }, 26);
  })();

  /* ---- wallpaper viewer ---- */
  (function viewer() {
    var v = document.getElementById("wpView");
    if (!v) return;
    var img = v.querySelector("img"), cap = v.querySelector("figcaption");
    document.querySelectorAll("[data-wp-src]").forEach(function (b) {
      b.addEventListener("click", function () {
        img.src = b.dataset.wpSrc; img.alt = b.dataset.wpName + " wallpaper preview";
        cap.textContent = b.dataset.wpName + " — " + b.dataset.wpStyle + " (real file: wallpapers/" + b.dataset.wpFile + ")";
      });
    });
  })();
})();
