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

    const API_BODY = {
      query: [
        {
          code: "index",
          selection: {
            filter: "item",
            values: ["0"], // total CPI
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

      const fromLabel = labelByIdx[fromIdxKey] || "";
      const toLabel = labelByIdx[toIdxKey] || "";

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

        const timeDim = dataset.dimension.time;
        const labelMap = timeDim && timeDim.category && timeDim.category.label;
        const vals = dataset.value;
        const n =
          dataset.size && dataset.size[0] ? dataset.size[0] : vals.length;

        if (!labelMap || !Array.isArray(vals)) {
          metaSpan.textContent =
            "Manglende tidsdimension eller værdier i json-stat.";
          throw new Error("Missing time labels or values");
        }

        const indices = [];
        for (let i = 0; i < n; i++) {
          const v = vals[i];
          const lab = labelMap[String(i)];

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
          const lab = labelByIdx[key] || "";

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
        toLabelSpan.textContent = labelByIdx[newestKey] || "";

        // Default "Fra" = 2008 januar if present, otherwise oldest
        let fromDefaultIdx = sortedIndices[sortedIndices.length - 1]; // oldest
        for (const idx of sortedIndices) {
          const key = String(idx);
          const lab = (labelByIdx[key] || "").toLowerCase();
          if (lab.includes("2008") && lab.includes("januar")) {
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