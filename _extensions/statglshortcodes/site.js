// site.js
(function () {

  // ---- config ----------------------------------------------------
  var LANGS = ["da", "en", "kl"];
  var LANG_RE = new RegExp("^/(" + LANGS.join("|") + ")(/|$)");

  var LANGS = ["da", "en", "kl"];
  var LANG_RE = new RegExp("^/(" + LANGS.join("|") + ")(/|$)");

  // ---- navigation spec -------------------------------------------
  // Single source of truth for the navbar. The data-nav keys in
  // _quarto.yml are the only contract; labels, hrefs and per-language
  // availability live here. An item with no href for the current
  // language is removed from the navbar rather than left as a dead
  // link, so /en/ (no method pages yet) simply gets a shorter menu.
  // TODO(kl): the Greenlandic labels marked below need a native check.

  var NAV = {
    "statistics": {
      // Dropdown parent: label only, no href.
      label: { da: "Statistik", kl: "Kisitsisit", en: "Statistics" }
    },
    "statistics.inuit": {
      label: { da: "Personer", kl: "Inuit", en: "Society" },
      href: {
        da: "/da/statistics/inuit/",
        kl: "/kl/statistics/inuit/",
        en: "/en/statistics/inuit/"
      }
    },
    "statistics.aningaasat": {
      label: { da: "\u00d8konomi", kl: "Aningaasat", en: "Economy" },
      href: {
        da: "/da/statistics/aningaasat/",
        kl: "/kl/statistics/aningaasat/",
        en: "/en/statistics/aningaasat/"
      }
    },
    "statistics.sila": {
      label: { da: "Energi og klima", kl: "Sila", en: "Environment" },
      href: {
        da: "/da/statistics/sila/",
        kl: "/kl/statistics/sila/",
        en: "/en/statistics/sila/"
      }
    },
    "statistics.all": {
      label: { da: "Alle emner", kl: "Kisitsisit tamarmik", en: "All statistics" }, // TODO(kl)
      exact: true, // overview page only, not every page below /statistics/
      href: {
        da: "/da/statistics/",
        kl: "/kl/statistics/",
        en: "/en/statistics/"
      }
    },
    "release": {
      // Dropdown parent: label only, no href. Children carry all three langs,
      // so the dropdown looks the same in kl/da/en.
      label: { da: "Udgivelser", kl: "Saqqummersitassat", en: "Releases" }
    },
    "release.calendar": {
      label: {
        da: "Udgivelseskalender",
        kl: "Saqqummersitassanut nalunaaqutsiut",
        en: "Release calendar"
      },
      href: {
        da: "/da/release.html",
        kl: "/kl/release.html",
        en: "/en/release.html"
      }
    },
    "release.news": {
      label: { da: "Seneste nyt", kl: "Nutaarsiassat", en: "Latest releases" }, // TODO(kl)
      // Posts are Danish only for now. en/releases/index.qmd is a hand-written
      // placeholder pointing at the da listing; kl goes straight there (TODO kl).
      href: { da: "/da/releases/", kl: "/da/releases/", en: "/en/releases/" }
    },
    "release.gif": {
      label: { da: "Gr\u00f8nland i tal", kl: "Kalaallit Nunaat kisitsisitigut", en: "Greenland in Figures" }, // TODO(kl)
      href: { da: "/da/gif/", kl: "/kl/gif/", en: "/en/gif/" }
    },
    "release.archive": {
      label: { da: "Statistikarkiv", kl: "Kisitsisit toqqorsivii", en: "Statistics archive" }, // TODO(kl)
      href: { da: "/da/archive/", kl: "/kl/archive/", en: "/en/archive/" }
    },
    "docs": {
      // No English method pages yet; en/docs/index.qmd is a hand-written
      // placeholder that points at the da/kl docs.
      label: { da: "Metode", kl: "Periaaseq", en: "Methods" },
      href: {
        da: "/da/docs/",
        kl: "/kl/docs/",
        en: "/en/docs/"
      }
    },
    "about": {
      label: { da: "Om", kl: "Pilluta", en: "About" },
      href: {
        da: "/da/about/",
        kl: "/kl/about/",
        en: "/en/about/"
      }
    },
    "statbank": {
      label: { da: "Statistikbanken", kl: "Statistikbank", en: "StatBank" }, // TODO(kl)
      href: {
        da: "https://bank.stat.gl/pxweb/da/Greenland/",
        kl: "https://bank.stat.gl/pxweb/kl/Greenland/",
        en: "https://bank.stat.gl/pxweb/en/Greenland/"
      },
      external: true
    }
  };

  // Sections that are not in the navbar but that the language switch still
  // needs to know about, so it never swaps into a folder that has no
  // counterpart. Same shape as NAV, hrefs only.
  var EXTRA_PATHS = {
    "tema": { href: { da: "/da/tema/", kl: "/kl/tema/", en: "/en/tema/" } }
  };

  // Everything the language switch consults, navbar items first.
  var PATHS = Object.assign({}, NAV, EXTRA_PATHS);

  // Language switch: display order and the short codes shown in the navbar.
  var LANG_ORDER = ["kl", "da", "en"];
  var LANG_SHORT = { kl: "KL", da: "DA", en: "EN" };
  var LANG_NAME  = { kl: "Kalaallisut", da: "Dansk", en: "English" };
  var LANG_SWITCH_ARIA = "Kalaallisut / Dansk / English";

  // ---- helpers ---------------------------------------------------

  function getCurrentLang() {
    var path = window.location.pathname || "/";
    var m = path.match(LANG_RE);
    return m ? m[1] : LANGS[0];
  }

  function buildUrlForLang(targetLang) {
    var loc = window.location;
    var path = loc.pathname || "/";

    // Replace existing prefix
    if (LANG_RE.test(path)) {
      path = path.replace(LANG_RE, "/" + targetLang + "$2");
    } else {
      // Prepend new prefix
      path = "/" + targetLang + "/" + path.replace(/^\/+/, "");
    }

    // Guarantee trailing slash for root
    if (path === "/" + targetLang) path += "/";

    return loc.origin + path + loc.search + loc.hash;
  }

  // ---- global switch function -----------------------------------
// inside (function () { ... })

window.findBestAnchor = function () {
  // Always compute from scroll position. Don't trust location.hash:
  // it can be stale (user landed via #X, then scrolled past it), and
  // honouring it would lock subsequent language switches to the old anchor.
  const main =
    document.querySelector("main") ||
    document.querySelector("#quarto-content") ||
    document.body;

  const candidates = Array.from(
    main.querySelectorAll(".shorty[id], h2[id], h3[id], h4[id], section[id]")
  );

  const IGNORE = new Set(["toc-title", "TOC"]);
  const IGNORE_PREFIXES = ["toc-", "quarto-", "navbar", "nav-", "sidebar", "footer"];

  function shouldIgnore(el) {
    const id = el.id;
    if (!id) return true;
    if (IGNORE.has(id)) return true;
    if (IGNORE_PREFIXES.some(p => id.startsWith(p))) return true;
    if (el.closest("nav") || el.closest("#TOC") || el.closest(".toc")) return true;
    return false;
  }

  // Only pick a heading the user has actually scrolled past (top <= 0).
  // If nothing has been passed (e.g. user is at the top of the page),
  // return "" so the language switch keeps the URL clean and the
  // sessionStorage scrollY fallback restores exact position.
  let best = null;
  let bestTop = -Infinity;

  for (const el of candidates) {
    if (shouldIgnore(el)) continue;

    const r = el.getBoundingClientRect();
    if (r.top > 0) continue; // not yet scrolled past

    // Largest top (closest to 0 from below) wins = most recently passed.
    let score = r.top;
    if (el.matches("section[id]")) score -= 5; // mild preference for h-tags

    if (score > bestTop) {
      bestTop = score;
      best = el;
    }
  }

  return best ? best.id : "";
};
// Sections are not translated in lockstep: /en/ has no method pages, tema
// or news. Find the NAV
// entry the current page belongs to and see what the target language has
// in its place.
function navMatchForPath(targetLang) {
  var here = getCurrentLang();
  var path = (window.location.pathname || "/").replace(/index\.html$/, "");
  for (var key in PATHS) {
    var href = PATHS[key].href;
    if (!href || !href[here] || /^https?:/i.test(href[here])) continue;
    var mine = href[here];
    var isSection = mine.charAt(mine.length - 1) === "/";
    var hit = isSection
      ? path.indexOf(mine) === 0
      : (path === mine || path === mine.replace(/\.html$/, ""));
    if (hit) return { fromSection: isSection, to: href[targetLang] || null };
  }
  return null; // page we know nothing about: plain prefix swap
}

// Where the language switch should point: the same page in the other
// language when it can exist, otherwise the nearest thing that does.
window.statglLangUrl = function (targetLang) {
  var m = navMatchForPath(targetLang);
  if (!m) return buildUrlForLang(targetLang);

  // Nothing in that language: fall back to its front page.
  if (m.to === null) return window.location.origin + "/" + targetLang + "/";

  // Section to section: keep the rest of the path (prefix swap).
  if (m.fromSection && m.to.charAt(m.to.length - 1) === "/") {
    return buildUrlForLang(targetLang);
  }

  // Single page on either side: go to that page.
  return window.location.origin + m.to;
};

window.statglSwitchLang = function (targetLang) {
  if (!targetLang) return;

  var mapped = window.statglLangUrl(targetLang);
  if (mapped !== buildUrlForLang(targetLang)) {
    window.location.href = mapped;   // no counterpart page: skip the anchor
    return;
  }

  const anchor = window.findBestAnchor ? window.findBestAnchor() : "";
  let url = buildUrlForLang(targetLang);

  if (anchor) {
    url = url.replace(/#.*$/, "") + "#" + anchor;
  } else {
    sessionStorage.setItem("statglScrollY", String(window.scrollY || 0));
  }

  window.location.href = url;
};

// on load:
window.addEventListener("DOMContentLoaded", () => {
  if (location.hash) return;
  const y = sessionStorage.getItem("statglScrollY");
  if (!y) return;
  sessionStorage.removeItem("statglScrollY");
  window.scrollTo(0, parseInt(y, 10) || 0);
});

  // ---- logo behaviour -------------------------------------------

  function initLogoHome() {
    var logo = document.querySelector(
      ".quarto-navbar-logo, .navbar-brand, .quarto-navbar-brand, .navbar-logo"
    );
    if (!logo) return;

    logo.addEventListener("click", function (e) {
      e.preventDefault();
      window.location.href = "/" + getCurrentLang() + "/";
    });
  }

  // ---- navbar ----------------------------------------------------

  function navLabel(entry, lang) {
    if (!entry || !entry.label) return "";
    return entry.label[lang] || entry.label[LANGS[0]] || "";
  }

  // Does href point at the page (or section) we are currently on?
  function isCurrent(href, path, exact) {
    if (!href || /^https?:/i.test(href)) return false;
    var t = href.replace(/index\.html$/, "").replace(/\.html$/, "");
    var p = path.replace(/index\.html$/, "").replace(/\.html$/, "");
    if (t.charAt(t.length - 1) === "/" && !exact) return p.indexOf(t) === 0; // section
    return p === t || p + "/" === t;                                        // single page
  }

  function isDivider(li) {
    return !!li && !li.querySelector("a") && !!li.querySelector("hr, .dropdown-divider");
  }

  function tidyDropdown(menu) {
    var items = Array.prototype.slice.call(menu.children);
    // Drop leading/trailing dividers, and any that ended up doubled up.
    var prevWasDivider = true;
    items.forEach(function (li) {
      if (isDivider(li)) {
        if (prevWasDivider) li.remove();
        else prevWasDivider = true;
      } else {
        prevWasDivider = false;
      }
    });
    var rest = Array.prototype.slice.call(menu.children);
    while (rest.length && isDivider(rest[rest.length - 1])) {
      rest.pop().remove();
    }
    return menu.querySelectorAll("a");
  }

  // A dropdown with a single surviving child is worse than a plain link:
  // keep the parent's label, take the child's destination.
  function collapseDropdown(dd, menu, only) {
    var toggle = dd.querySelector(".dropdown-toggle");
    if (!toggle) return;

    toggle.setAttribute("href", only.getAttribute("href"));
    toggle.classList.remove("dropdown-toggle");
    toggle.removeAttribute("data-bs-toggle");
    toggle.removeAttribute("aria-expanded");
    if (only.classList.contains("active")) {
      toggle.classList.add("active");
      toggle.setAttribute("aria-current", "page");
    }

    dd.classList.remove("dropdown");
    menu.remove();
  }

  function initNav() {
    var lang = getCurrentLang();
    var path = window.location.pathname || "/";

    document.querySelectorAll(".nav-i18n[data-nav]").forEach(function (span) {
      var entry = NAV[span.getAttribute("data-nav")];
      var link = span.closest("a");
      var item = span.closest("li");
      if (!entry || !link || !item) return;

      span.textContent = navLabel(entry, lang);

      // Dropdown parents carry no href; their fate follows their children.
      if (item.classList.contains("dropdown")) return;

      var href = entry.href && entry.href[lang];
      if (!href) {          // page does not exist in this language
        item.remove();
        return;
      }

      link.setAttribute("href", href);

      if (entry.external) {
        link.setAttribute("target", "_blank");
        link.setAttribute("rel", "noopener");
        link.classList.add("nav-external");
        return;
      }

      if (isCurrent(href, path, entry.exact)) {
        link.classList.add("active");
        link.setAttribute("aria-current", "page");
      }
    });

    // Empty dropdown -> remove. One child left -> collapse to a plain link
    // (kl/en have only the release calendar). Child on the current page ->
    // light up the parent.
    document.querySelectorAll(".navbar li.dropdown").forEach(function (dd) {
      var menu = dd.querySelector(".dropdown-menu");
      if (!menu) return;

      var links = tidyDropdown(menu);
      if (links.length === 0) {
        dd.remove();
        return;
      }
      if (links.length === 1) {
        collapseDropdown(dd, menu, links[0]);
        return;
      }
      if (menu.querySelector("a.active")) {
        var toggle = dd.querySelector(".dropdown-toggle");
        if (toggle) toggle.classList.add("active");
      }
    });
  }

  // ---- language switch (GL | DK | EN) ----------------------------

  function initLangSwitch() {
    var navbar = document.querySelector(".navbar");
    if (!navbar || navbar.querySelector(".lang-switch")) return;

    var container = navbar.querySelector(".navbar-container") || navbar;
    var slot = container.querySelector(".quarto-navbar-tools");
    if (!slot) {
      slot = document.createElement("div");
      slot.className = "quarto-navbar-tools";
      var toggler = container.querySelector(".navbar-toggler");
      if (toggler) container.insertBefore(slot, toggler.nextSibling);
      else container.appendChild(slot);
    }

    var current = getCurrentLang();
    var group = document.createElement("div");
    group.className = "lang-switch";
    group.setAttribute("role", "group");
    group.setAttribute("aria-label", LANG_SWITCH_ARIA);

    LANG_ORDER.forEach(function (l, i) {
      if (i) {
        var sep = document.createElement("span");
        sep.className = "lang-switch__sep";
        sep.setAttribute("aria-hidden", "true");
        sep.textContent = "|";
        group.appendChild(sep);
      }

      // A real href keeps the link crawlable and middle-clickable; the
      // handler adds the anchor/scroll preservation from statglSwitchLang.
      var a = document.createElement("a");
      a.className = "lang-switch__btn" + (l === current ? " is-active" : "");
      a.href = window.statglLangUrl(l);
      a.setAttribute("hreflang", l);
      a.setAttribute("lang", l);
      a.setAttribute("title", LANG_NAME[l]);
      a.textContent = LANG_SHORT[l];
      if (l === current) a.setAttribute("aria-current", "true");
      a.addEventListener("click", function (e) {
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
        e.preventDefault();
        if (l !== current) window.statglSwitchLang(l);
      });
      group.appendChild(a);
    });

    slot.appendChild(group);
  }

  // ---- in-page language links (.lang-link[data-lang]) ------------

  function initLangMenu() {
    document.querySelectorAll(".lang-link[data-lang]").forEach(function (span) {
      var targetLang = span.getAttribute("data-lang");
      var link = span.closest("a");
      if (!link) return;
      link.addEventListener("click", function (e) {
        e.preventDefault();
        window.statglSwitchLang(targetLang);
      });
    });
  }

  function setActiveLang() {
    var current = getCurrentLang();
    document.querySelectorAll(".lang-link").forEach(function (el) {
      el.classList.toggle("active-lang", el.getAttribute("data-lang") === current);
    });
  }

  // ---- public init ----------------------------------------------

  window.statglInit = function () {
    var navbar = document.querySelector(".navbar");
    try {
      initLogoHome();
      initNav();
      initLangSwitch();
      initLangMenu();
      setActiveLang();
    } finally {
      // Reveal the navbar even if something above threw, so a broken
      // init never leaves the site without navigation.
      if (navbar) navbar.classList.add("nav-ready");
    }
  };

  // ---- auto-init on DOM load ------------------------------------
  document.addEventListener("DOMContentLoaded", window.statglInit);

})();

(function () {
  // Remember the original fetch
  const originalFetch = window.fetch;

  window.fetch = function (input, init) {
    const url = typeof input === "string" ? input : (input && input.url);

    // Only intercept the search index
    if (url && /search\.json(\?|$)/.test(url)) {
      return originalFetch(input, init).then(function (response) {
        // If fetch fails or isn't OK, just pass it through
        if (!response || !response.ok) {
          return response;
        }

        // Figure out which language we are on from the URL path: /da/... /en/... /kl/...
        var path = window.location.pathname.replace(/^\/+/, ""); // strip leading "/"
        var firstSegment = path.split("/")[0];                   // "da", "en", "kl", or ""

        // If we don't detect a language, don't filter at all
        if (!firstSegment || !/^(da|en|kl)$/.test(firstSegment)) {
          return response;
        }

        var langPrefix = firstSegment + "/";

        // Read the JSON, filter it, and return a new Response with the filtered data
        return response.clone().json().then(function (data) {
          var filtered = (data || []).filter(function (item) {
            // Be defensive about missing hrefs
            if (!item || !item.href) return false;
            return item.href.indexOf(langPrefix) === 0;
          });

          var blob = new Blob([JSON.stringify(filtered)], {
            type: "application/json"
          });

          // Keep status + headers from original response
          var initResp = {
            status: response.status,
            statusText: response.statusText,
            headers: response.headers
          };

          return new Response(blob, initResp);
        });
      });
    }

    // Everything else: normal fetch
    return originalFetch(input, init);
  };
})();

(function () {
  // ---- search: multi-word OR with AND-boost ----------------------
  // Quarto's stock Fuse index treats "word1 word2" as one near-contiguous
  // pattern (threshold 0.1, no extended search), so two-word queries return
  // almost nothing. We wrap window.Fuse before Quarto builds its index
  // (lazy, on first search) to:
  //   1. enable extended search + a looser threshold,
  //   2. rewrite "a b" -> "a | b" so EITHER term matches (recall),
  //   3. re-sort so hits containing MORE of the terms float to the top.
  // Lives in our file, so it survives every rebuild of the Quarto bundle.

  var THRESHOLD = 0.3; // was 0.1; looser = tolerates typos/stems, more recall

  function fields(item) {
    if (!item) return "";
    return ((item.title || "") + " " + (item.section || "") + " " + (item.text || ""))
      .toLowerCase();
  }

  function patchFuse() {
    if (!window.Fuse || window.__statglFusePatched) return !!window.__statglFusePatched;
    var OrigFuse = window.Fuse;

    function StatglFuse(list, options) {
      var inst = new OrigFuse(list, Object.assign({}, options, {
        useExtendedSearch: true,
        threshold: THRESHOLD
      }));

      var origSearch = inst.search.bind(inst);
      inst.search = function (query, opts) {
        var terms = String(query == null ? "" : query).trim().split(/\s+/).filter(Boolean);
        if (terms.length < 2) return origSearch(query, opts);

        // OR across terms. Each bare term is fuzzy-matched in extended search.
        var results = origSearch(terms.join(" | "), opts);
        if (!Array.isArray(results)) return results;

        var lowered = terms.map(function (t) { return t.toLowerCase(); });
        results.forEach(function (r) {
          var hay = fields(r.item);
          r.__matched = lowered.reduce(function (n, t) {
            return n + (hay.indexOf(t) >= 0 ? 1 : 0);
          }, 0);
        });
        results.sort(function (a, b) {
          if (b.__matched !== a.__matched) return b.__matched - a.__matched; // more terms first
          return (a.score || 0) - (b.score || 0);                            // then Fuse score
        });
        return results;
      };

      return inst;
    }

    // Preserve prototype + any statics Quarto might reach for.
    StatglFuse.prototype = OrigFuse.prototype;
    Object.keys(OrigFuse).forEach(function (k) { StatglFuse[k] = OrigFuse[k]; });

    window.Fuse = StatglFuse;
    window.__statglFusePatched = true;
    return true;
  }

  // Fuse may not be on window yet depending on script order; poll briefly.
  if (!patchFuse()) {
    var tries = 0;
    var iv = setInterval(function () {
      if (patchFuse() || ++tries > 100) clearInterval(iv);
    }, 50);
  }
})();

document.addEventListener("DOMContentLoaded", () => {
  // Only touch your custom tema listing
  document.querySelectorAll("#listing-tema-listing .tema-listing > p").forEach((p) => {
    const parent = p.parentNode;
    if (!parent) return;

    // If this <p> only contains an empty <a>, remove it entirely
    const onlyChild = p.children.length === 1 ? p.children[0] : null;
    const isEmptyA =
      onlyChild &&
      onlyChild.tagName === "A" &&
      (onlyChild.textContent || "").trim() === "" &&
      onlyChild.children.length === 0;

    if (isEmptyA) {
      p.remove();
      return;
    }

    // Otherwise, unwrap: move children out, then remove <p>
    while (p.firstChild) parent.insertBefore(p.firstChild, p);
    p.remove();
  });
});
// Expose the fixed header height as a CSS variable so styles.css can keep
// the sidebar offset when headroom "unpins" on desktop (navbar locked there).
(function () {
  function setHeaderVar() {
    var h = document.querySelector("header.fixed-top");
    document.documentElement.style.setProperty(
      "--statgl-header-h", (h ? h.clientHeight : 0) + "px"
    );
  }
  document.addEventListener("DOMContentLoaded", setHeaderVar);
  window.addEventListener("load", setHeaderVar);
  window.addEventListener("resize", setHeaderVar);
})();
// ---- accessibility (WCAG 2.2 AA, 2026-10-15; see intern/tilgaengelighed.qmd)
// Things Quarto and the templates get wrong in the same way on every page,
// fixed once here rather than in the qmds.
(function () {
  var LABELS = {
    da: { nav: "Hovedmenu", side: "Sider i afsnittet", toc: "Indhold på siden", search: "Søg", logo: "Grønlands Statistik, forside", newwin: "(åbner i nyt vindue)" },
    kl: { nav: "Pingaarnertut", side: "Immikkoortumi quppernerit", toc: "Quppernermi imarisaa", search: "Ujarlerit", logo: "Kalaallit Nunaanni Naatsorsueqqissaartarfik, saqqaa", newwin: "(ruujorimi nutaami ammarneqassaaq)" },
    en: { nav: "Main menu", side: "Pages in this section", toc: "On this page", search: "Search", logo: "Statistics Greenland, front page", newwin: "(opens in a new window)" }
  };
  function a11yInit() {
    var lang = (document.documentElement.lang || "da").slice(0, 2);
    var L = LABELS[lang] || LABELS.da;

    // 1.3.1 Two unnamed <nav>s (navbar, TOC) read as "navigation, navigation".
    var nav = document.querySelector("#quarto-header nav.navbar");
    if (nav && !nav.getAttribute("aria-label")) nav.setAttribute("aria-label", L.nav);
    document.querySelectorAll('nav[role="doc-toc"], nav#TOC').forEach(function (t) {
      if (!t.getAttribute("aria-label")) t.setAttribute("aria-label", L.toc);
    });
    document.querySelectorAll("nav#quarto-sidebar, nav.quarto-secondary-nav").forEach(function (t) {
      if (!t.getAttribute("aria-label")) t.setAttribute("aria-label", L.side);
    });

    // 2.4.4 Logo link has no text (Quarto writes alt="" on the logo);
    // search button is "Search" in every language.
    var logo = document.querySelector("a.navbar-brand-logo");
    if (logo && !logo.getAttribute("aria-label")) logo.setAttribute("aria-label", L.logo);
    document.querySelectorAll(".aa-DetachedSearchButton, #quarto-search button").forEach(function (b) {
      b.setAttribute("aria-label", L.search);
    });

    // 2.4.4 Card templates use an empty <a class="stretched-link"> over the
    // card; name it after the card's title so it is not "link" to a reader.
    document.querySelectorAll("a.stretched-link").forEach(function (a) {
      if ((a.textContent || "").trim() || a.getAttribute("aria-label")) return;
      var card = a.closest(".card, .tema-card, .sectioncard, li, article") || a.parentElement;
      var title = card && card.querySelector("h1, h2, h3, h4, .card-title, .listing-title, .tema-card-title, .externcard-title");
      var text = (title && (title.textContent || "").trim().replace(/\s+/g, " ")) || (card && card.getAttribute("aria-label"));
      if (text) a.setAttribute("aria-label", text);
    });

    // 3.2.5 Links that open a new window (statbank, PDFs) say so to a reader.
    // Several lua/ejs sources set target="_blank", so it is done once here.
    document.querySelectorAll('a[target="_blank"]').forEach(function (a) {
      if (a.querySelector(".a11y-newwin")) return;
      var label = a.getAttribute("aria-label");
      if (label) { a.setAttribute("aria-label", label + " " + L.newwin); return; }
      var s = document.createElement("span");
      s.className = "visually-hidden a11y-newwin";
      s.textContent = " " + L.newwin;
      a.appendChild(s);
    });

    // 2.4.4 anchor.js names every heading link "Anchor", so each card heading
    // is read as "Nøgletal Anchor". The links stay for the mouse; the TOC
    // covers keyboard and screen-reader users.
    document.querySelectorAll("a.anchorjs-link").forEach(function (a) {
      a.setAttribute("aria-hidden", "true");
      a.setAttribute("tabindex", "-1");
    });

    // 4.1.2 shorty hides its visible card title (the TOC header is the real
    // one), but anchor.js still drops a focusable link inside it.
    document.querySelectorAll('[aria-hidden="true"] a, [aria-hidden="true"] button').forEach(function (el) {
      el.setAttribute("tabindex", "-1");
    });

    // 2.1.1 Horizontally scrolling code blocks and wide tables need to be
    // reachable with Tab to be scrolled with the keyboard.
    // 1.4.10 Markdown tables (docs pages) have no scrolling wrapper, so a wide
    // one forces the page to scroll sideways on a phone.
    document.querySelectorAll("main table").forEach(function (t) {
      if (t.closest(".table-responsive, .shorty-table-wrapper, [style*='overflow']")) return;
      var wrap = document.createElement("div");
      wrap.className = "table-responsive";
      t.parentNode.insertBefore(wrap, t);
      wrap.appendChild(t);
    });
    focusScrollable();
  }
  function focusScrollable() {
    document.querySelectorAll("div.sourceCode, pre, .shorty-table-wrapper, .table-responsive").forEach(function (el) {
      if (el.scrollWidth > el.clientWidth && !el.hasAttribute("tabindex")) el.setAttribute("tabindex", "0");
    });
  }
  // After initNav/initLangSwitch and anchor.js (both run on DOMContentLoaded);
  // overflow is re-checked once web fonts are in and when the window resizes.
  window.addEventListener("load", a11yInit);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(focusScrollable);
  window.addEventListener("resize", focusScrollable);
})();
