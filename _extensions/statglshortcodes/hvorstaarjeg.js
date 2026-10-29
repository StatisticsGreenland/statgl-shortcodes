window.initHvorStaarJeg = function (id) {
  const root = document.getElementById(id);
  if (!root) {
    console.error("hvorstaarjeg: root not found", id);
    return;
  }

  const dataEl = root.querySelector(".pct-data");
  if (!dataEl) {
    console.error("hvorstaarjeg: embedded data element not found");
    return;
  }

  let D;
  try {
    D = JSON.parse(dataEl.textContent);
  } catch (e) {
    console.error("hvorstaarjeg: invalid JSON", e);
    return;
  }

  const values = Array.isArray(D.vaerdier) ? D.vaerdier : [];
  if (!values.length) {
    console.error("hvorstaarjeg: D.vaerdier missing or empty", D);
    return;
  }

  // i18n: read strings injected by the shortcode; fall back to Danish defaults
  let i18n = {};
  const i18nEl = root.querySelector(".pct-i18n");
  if (i18nEl) {
    try { i18n = JSON.parse(i18nEl.textContent); } catch (e) {}
  }
  const i18nDefaults = {
    resultSuffix: "af personer i Grønland tjener <em>mindre<\/em> end dig.",
    guessHigher:  "Du gættede {guess} % — det faktiske tal er <b>{diff} procentpoint højere<\/b>.",
    guessLower:   "Du gættede {guess} % — det faktiske tal er <b>{diff} procentpoint lavere<\/b>.",
    guessExact:   "Du ramte præcis!"
  };

  // t(key, vars) — look up i18n string, substitute {placeholder} tokens
  function t(key, vars) {
    let s = (key in i18n) ? i18n[key] : i18nDefaults[key];
    if (!s) s = "";
    if (vars) {
      Object.keys(vars).forEach(function (k) {
        s = s.split("{" + k + "}").join(String(vars[k]));
      });
    }
    return s;
  }

  const inputIncome = document.getElementById(id + "-indkomst");
  const inputGuess  = document.getElementById(id + "-gaet");
  const guessVis    = document.getElementById(id + "-gaet-vis");

  const step1        = root.querySelector(".pct-step1");
  const step2        = root.querySelector(".pct-step2");
  const resultEl     = root.querySelector(".pct-resultat");
  const barContainer = root.querySelector(".pct-bar-container");

  const revealBtn = root.querySelector(".pct-reveal-btn");
  const resetBtn  = root.querySelector(".pct-reset-btn");

  if (!inputIncome || !inputGuess || !guessVis || !step1 || !step2 || !resultEl || !barContainer || !revealBtn || !resetBtn) {
    console.error("hvorstaarjeg: missing required DOM elements");
    return;
  }

  function est(v) {
    const a = values;
    const n = a.length;

    if (v <= a[0]) {
      return Math.max(0, Math.round((v / a[0]) * 10));
    }

    if (v >= a[n - 1]) {
      return Math.min(99, Math.round(90 + ((v - a[n - 1]) / (a[n - 1] * 0.5)) * 9));
    }

    for (let i = 0; i < n - 1; i++) {
      if (v >= a[i] && v <= a[i + 1]) {
        return Math.round((i + 1) * 10 + ((v - a[i]) / (a[i + 1] - a[i])) * 10);
      }
    }

    return 50;
  }

  function fmt(n) {
    return n.toLocaleString("da-DK", { maximumFractionDigits: 0 });
  }

  function updateGuessLabel() {
    guessVis.textContent = inputGuess.value + " %";
  }

  function renderBar(percentile) {
    const p = Math.min(99, Math.max(1, percentile));
    let html = '<div class="pct-bar">';

    for (let i = 0; i < 10; i++) {
      html += '<div class="pct-segment"></div>';
    }

    html += '<div class="pct-marker" style="left:' + p + '%"></div>';
    html += "</div>";

    barContainer.innerHTML = html;
  }

  function reveal() {
    const v = parseInt(inputIncome.value, 10) || 0;
    const g = parseInt(inputGuess.value, 10) || 0;
    const f = est(v);
    const d = f - g;

    let comparison;
    if (d > 0) {
      comparison = t("guessHigher", { guess: g, diff: d });
    } else if (d < 0) {
      comparison = t("guessLower", { guess: g, diff: Math.abs(d) });
    } else {
      comparison = t("guessExact");
    }

    resultEl.innerHTML =
      '<p class="pct-main-result"><b>' + fmt(f) + " %</b> " + t("resultSuffix") + "</p>" +
      '<p class="pct-sub-result text-muted small mb-0">' + comparison + "</p>";

    renderBar(f);
    step1.classList.add("d-none");
    step2.classList.remove("d-none");
  }

  function reset() {
    step1.classList.remove("d-none");
    step2.classList.add("d-none");
  }

  inputGuess.addEventListener("input", updateGuessLabel);
  revealBtn.addEventListener("click", reveal);
  resetBtn.addEventListener("click", reset);

  updateGuessLabel();
};