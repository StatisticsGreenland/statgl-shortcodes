// _extensions/StatisticsGreenland/statglshortcodes/site.js
(function () {
  // --------- helpers -------------------------------------------------

  // Get current language prefix from the path: /da/, /en/, /kl/
  function getCurrentLang() {
    var path = window.location.pathname || "/";
    var match = path.match(/^\/(da|en|kl)(\/|$)/);
    return match ? match[1] : "da"; // default to Danish if none
  }

  // Build a full URL for the same page but with a different language prefix
  function buildUrlForLang(targetLang) {
    var loc = window.location;
    var path = loc.pathname || "/";

    // If the path starts with /da/, /en/ or /kl/, replace that prefix
    if (/^\/(da|en|kl)(\/|$)/.test(path)) {
      path = path.replace(/^\/(da|en|kl)(\/|$)/, "/" + targetLang + "$2");
    } else {
      // No language prefix yet: just add it in front
      if (!path.startsWith("/")) {
        path = "/" + path;
      }
      path = "/" + targetLang + path;
    }

    // Keep query string and hash if present
    return loc.origin + path + loc.search + loc.hash;
  }

  // --------- language switch buttons ---------------------------------

  // This is what your buttons call: statglSwitchLang('da'|'en'|'kl')
  window.statglSwitchLang = function (targetLang) {
    if (!targetLang) return;
    var url = buildUrlForLang(targetLang);
    window.location.href = url;
  };

  // --------- logo "go home" behaviour --------------------------------

  function initLogoHome() {
    // Adjust selectors if needed, but this usually covers Quarto navbar logos
    var logo = document.querySelector(".quarto-navbar-logo, .navbar-brand");
    if (!logo) return;

    logo.addEventListener("click", function (e) {
      e.preventDefault();
      var lang = getCurrentLang();
      // Go to the language root, e.g. /da/ or /en/ or /kl/
      window.location.href = "/" + lang + "/";
    });
  }

  // --------- public init called from template.html -------------------

  window.statglInit = function () {
    initLogoHome();
    // nothing else needed here; buttons use statglSwitchLang directly
  };
})();