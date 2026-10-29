// _extensions/StatisticsGreenland/statglshortcodes/statgl-filter.js
//
// Page-wide selector bus. Filters registered by id; subscribers opt in via
// HTML data attributes. Idempotent: re-loading the script is a no-op.
//
// Subscriber attributes:
//   data-filter-show="<id>:<value>"  toggle element visibility
//     <value> can be:
//        a literal     -> visible only when state[id] === value
//        "*"           -> visible only when state[id] is non-empty
//        "" (empty)    -> visible only when state[id] is empty (default)
//     Multiple rules can be combined with ";", all must match (AND).
//
//   data-filter-series="<id>"        toggle Highcharts series inside the
//     element. Each series' tags map (set via statgl_plot's series_tags)
//     is consulted: series with tags[id] === state[id] are shown, others
//     hidden. When state[id] is empty, all series are shown.
//
// Filter shortcode registers via window.StatglFilter.register("<id>").
//
(function () {
  if (window.StatglFilter) return;

  // -------------------- internal state ---------------------------------
  var state = {};        // { filterId: currentValue }
  var registered = {};   // { filterId: true } — for idempotent registration
  var hcHookInstalled = false;

  // -------------------- helpers ----------------------------------------
  function getChartFor(el) {
    if (!window.Highcharts || !Highcharts.charts) return null;
    for (var i = 0; i < Highcharts.charts.length; i++) {
      var c = Highcharts.charts[i];
      if (!c || !c.renderTo) continue;
      if (c.renderTo === el || el.contains(c.renderTo)) return c;
    }
    return null;
  }

  function reflowChartsInside(el) {
    if (!window.Highcharts || !Highcharts.charts) return;
    Highcharts.charts.forEach(function (c) {
      if (!c || !c.renderTo) return;
      if (el.contains(c.renderTo)) {
        try { c.reflow(); } catch (e) {}
      }
    });
  }

  function parseRules(spec) {
    // spec is "id:val" or "id:val; id2:val2"
    return spec.split(";").map(function (s) {
      return s.trim();
    }).filter(Boolean).map(function (rule) {
      var idx = rule.indexOf(":");
      if (idx < 0) return null;
      return { id: rule.slice(0, idx).trim(), value: rule.slice(idx + 1) };
    }).filter(Boolean);
  }

  function ruleMatches(rule) {
    var cur = state[rule.id] || "";
    if (rule.value === "*") return cur !== "";
    return cur === rule.value;
  }

  // -------------------- subscribers ------------------------------------
  // Visibility is class-based, not inline-style based. CSS in styles.css
  // hides `[data-filter-show]` by default (scoped to pages with a filter)
  // so the variants never flash visible before the JS runs. JS toggles
  // `.statgl-visible` to reveal the matching ones.
  function applyShow() {
    var elems = document.querySelectorAll("[data-filter-show]");
    elems.forEach(function (el) {
      var rules = parseRules(el.getAttribute("data-filter-show") || "");
      if (rules.length === 0) return;
      var wasHidden = !el.classList.contains("statgl-visible");
      var show = rules.every(ruleMatches);
      el.classList.toggle("statgl-visible", show);
      if (show && wasHidden) {
        // Charts that rendered while hidden have a zero width and need
        // a reflow once they're visible again.
        reflowChartsInside(el);
      }
    });
  }

  function applySeriesForContainer(el) {
    var id = el.getAttribute("data-filter-series");
    if (!id) return;
    var chart = getChartFor(el);
    if (!chart || !chart.series) return;
    var value = state[id] || "";

    chart.series.forEach(function (s) {
      if (!value) {
        if (!s.visible) s.setVisible(true, false);
        return;
      }
      var tag = s.options && s.options.tags && s.options.tags[id];
      var shouldShow = (tag === value);
      if (s.visible !== shouldShow) {
        s.setVisible(shouldShow, false);
      }
    });
    try { chart.redraw(false); } catch (e) {}
  }

  function applySeries() {
    var elems = document.querySelectorAll("[data-filter-series]");
    elems.forEach(applySeriesForContainer);
  }

  function applyAll() {
    applyShow();
    applySeries();
  }

  // -------------------- Highcharts load hook ---------------------------
  // Lazy-rendered charts (e.g. shorty IntersectionObserver path) may not
  // exist when the filter changes — when they finally load, apply current
  // state to them.
  function installHighchartsHook() {
    if (hcHookInstalled) return;
    if (!window.Highcharts) {
      setTimeout(installHighchartsHook, 200);
      return;
    }
    hcHookInstalled = true;
    Highcharts.addEvent(Highcharts.Chart, "load", function () {
      var chart = this;
      // Find the data-filter-series container this chart sits inside, if any.
      var el = chart.renderTo;
      while (el && el !== document.body) {
        if (el.getAttribute && el.getAttribute("data-filter-series")) {
          applySeriesForContainer(el);
          break;
        }
        el = el.parentNode;
      }
    });
  }

  // -------------------- public API -------------------------------------
  window.StatglFilter = {
    /** Register a <select id="<filterId>"> as a filter source. Safe to
     *  call multiple times for the same id (the second call is a no-op).
     */
    register: function (filterId) {
      if (registered[filterId]) return;
      var sel = document.getElementById(filterId);
      if (!sel) {
        // Element may not yet exist — defer.
        document.addEventListener("DOMContentLoaded", function () {
          window.StatglFilter.register(filterId);
        });
        return;
      }
      registered[filterId] = true;
      state[filterId] = sel.value || "";

      sel.addEventListener("change", function (e) {
        state[filterId] = e.target.value || "";
        applyAll();
      });

      installHighchartsHook();

      // Apply initial state once everything is parsed.
      if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", applyAll);
      } else {
        applyAll();
      }
    },

    /** Programmatically set a filter's value (also updates the <select>). */
    set: function (filterId, value) {
      var sel = document.getElementById(filterId);
      if (sel) sel.value = value;
      state[filterId] = value || "";
      applyAll();
    },

    /** Read the current state map (copy). */
    getState: function () {
      var copy = {};
      Object.keys(state).forEach(function (k) { copy[k] = state[k]; });
      return copy;
    }
  };
})();
