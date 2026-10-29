// _extensions/statglshortcodes/inflationcalc.js

(function () {
  /**
   * Initialize a single inflation calculator widget.
   * Expects HTML elements with IDs:
   *   <id>-amount, <id>-from, <id>-to, <id>-result, <id>-to-label, <id>-meta
   */
  window.initInflationCalc = function (id) {
    const amountInput = document.getElementById(`${id}-amount`);
    const fromSelect  = document.getElementById(`${id}-from`);
    const toSelect    = document.getElementById(`${id}-to`);
    const resultSpan  = document.getElementById(`${id}-result`);
    const toLabelSpan = document.getElementById(`${id}-to-label`);
    const metaSpan    = document.getElementById(`${id}-meta`);

    if (
      !amountInput ||
      !fromSelect ||
      !toSelect ||
      !resultSpan ||
      !toLabelSpan ||
      !metaSpan
    ) {
      console.warn(
        "initInflationCalc: missing one or more DOM elements for id:",
        id
      );
      return;
    }

    const API_URL =
      "https://bank.stat.gl:443/api/v1/da/Greenland/PR/PRXPRISF.px";

    // PRXPRISF has one index series per base period; the Jan 1971=100
    // series is the only one covering the full range (1971H1 onwards).
    // Ratios between periods are base-independent, so any series works.
    const API_BODY = {
      query: [
        {
          code: "indeks",
          selection: {
            filter: "item",
            values: ["1971H1"],
          },
        },
      ],
      response: {
        format: "json-stat",
      },
    };

    // Maps from original time index -> value/label
    const valueByIdx = {};
    const labelByIdx = {};

    // Half-year codes ("2008H2") shown as the half's first month, in the
    // page language (<html lang>): da/kl "jul. 2008", en "Jul 2008".
    // Anything that isn't a half-year code is shown unchanged.
    const LANG = (document.documentElement.lang || "da").slice(0, 2);
    const HALF_MONTH = {
      da: ["jan.", "jul."],
      kl: ["jan.", "jul."],
      en: ["Jan", "Jul"],
    }[LANG] || ["jan.", "jul."];
    function displayLabel(code) {
      const m = /^(\d{4})H([12])$/i.exec(String(code || "").trim());
      if (!m) return String(code || "");
      return HALF_MONTH[Number(m[2]) - 1] + " " + m[1];
    }
    let sortedIndices = []; // newest -> oldest

    function formatNumber(x) {
      return x.toLocaleString("da-DK", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      });
    }

    function updateResult() {
      const rawAmount = (amountInput.value || "")
        .toString()
        .replace(",", ".");
      const amount = parseFloat(rawAmount);

      const fromIdxKey = fromSelect.value;
      const toIdxKey = toSelect.value;

      const idxFrom = valueByIdx[fromIdxKey];
      const idxTo = valueByIdx[toIdxKey];

      if (
        !Number.isFinite(amount) ||
        !Number.isFinite(idxFrom) ||
        !Number.isFinite(idxTo)
      ) {
        resultSpan.textContent = "—";
        return;
      }

      const adjusted = amount * (idxTo / idxFrom);
      resultSpan.textContent = formatNumber(adjusted);

      const fromLabel = displayLabel(labelByIdx[fromIdxKey] || "");
      const toLabel = displayLabel(labelByIdx[toIdxKey] || "");

      toLabelSpan.textContent = toLabel;
      metaSpan.textContent =
        "(" +
        fromLabel +
        " = " +
        idxFrom +
        ", " +
        toLabel +
        " = " +
        idxTo +
        ").";
    }

    // Initial loading text (if not already set in HTML)
    if (!metaSpan.textContent) {
      metaSpan.textContent = "Henter prisindeks fra Statistikbanken …";
    }

    fetch(API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(API_BODY),
    })
      .then((resp) => {
        if (!resp.ok) {
          metaSpan.textContent =
            "Fejl: HTTP " + resp.status + " ved kald til Statistikbanken.";
          throw new Error("HTTP " + resp.status);
        }
        return resp.json();
      })
      .then((json) => {
        const dataset = json.dataset;
        if (!dataset || !dataset.dimension || !dataset.value) {
          metaSpan.textContent =
            "Kunne ikke tolke svaret fra Statistikbanken (json-stat).";
          throw new Error("Bad json-stat structure");
        }

        const timeDim = dataset.dimension.tid;
        const cat = timeDim && timeDim.category;
        const labelMap = cat && cat.label;
        const indexMap = cat && cat.index;
        const vals = dataset.value;

        if (!labelMap || !indexMap || !Array.isArray(vals)) {
          metaSpan.textContent =
            "Manglende tidsdimension eller værdier i json-stat.";
          throw new Error("Missing time labels or values");
        }

        // Only one indeks value is requested, so value[i] is period i
        const indices = [];
        for (const code of Object.keys(indexMap)) {
          const i = indexMap[code];
          const v = vals[i];
          const lab = labelMap[code];

          if (v == null || v === ".." || !lab) continue;

          valueByIdx[String(i)] = Number(v);
          labelByIdx[String(i)] = lab;
          indices.push(i);
        }

        if (!indices.length) {
          metaSpan.textContent =
            "Ingen prisindeks-data i svaret fra Statistikbanken.";
          return;
        }

        // Sort newest -> oldest by original time index
        sortedIndices = indices.sort((a, b) => b - a);

        // Clear both selects before populating
        fromSelect.innerHTML = "";
        toSelect.innerHTML = "";

        // Populate dropdowns in sorted order (newest -> oldest)
        sortedIndices.forEach((idx) => {
          const key = String(idx);
          const lab = displayLabel(labelByIdx[key] || "");

          const optFrom = document.createElement("option");
          optFrom.value = key;
          optFrom.textContent = lab;
          fromSelect.appendChild(optFrom);

          const optTo = document.createElement("option");
          optTo.value = key;
          optTo.textContent = lab;
          toSelect.appendChild(optTo);
        });

        // Default "Til" = newest (first in sorted list)
        const newestIdx = sortedIndices[0];
        const newestKey = String(newestIdx);
        toSelect.value = newestKey;
        toLabelSpan.textContent = displayLabel(labelByIdx[newestKey] || "");

        // Default "Fra" = 2008H1 if present, otherwise oldest
        let fromDefaultIdx = sortedIndices[sortedIndices.length - 1]; // oldest
        for (const idx of sortedIndices) {
          const lab = (labelByIdx[String(idx)] || "").toUpperCase();
          if (lab.startsWith("2008H1")) {
            fromDefaultIdx = idx;
            break;
          }
        }
        fromSelect.value = String(fromDefaultIdx);

        metaSpan.textContent = "";
        updateResult();
      })
      .catch((err) => {
        console.error("Inflationcalc PX json-stat error:", err);
        if (!metaSpan.textContent) {
          metaSpan.textContent =
            "Kunne ikke hente prisindeks fra Statistikbanken. Prøv igen senere.";
        }
        resultSpan.textContent = "—";
      });

    amountInput.addEventListener("input", updateResult);
    fromSelect.addEventListener("change", updateResult);
    toSelect.addEventListener("change", updateResult);
  };
})();