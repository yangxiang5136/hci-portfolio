/* Single source of truth for the portfolio card destinations, shared by the
   homepage modal and by scripts/check-demo-language.mjs so the language that a
   demo card hands to its demo is asserted rather than assumed. */
(function (global) {
  function resolvePortfolioDestination(destinationUrl, destinationKind, language, baseHref) {
    if (!destinationUrl) {
      return "";
    }
    if (destinationKind !== "demo") {
      return destinationUrl;
    }
    var demoUrl = new URL(destinationUrl, baseHref);
    demoUrl.searchParams.set("lang", language === "en" ? "en" : "zh");
    return demoUrl.pathname + demoUrl.search + demoUrl.hash;
  }

  global.resolvePortfolioDestination = resolvePortfolioDestination;
})(typeof globalThis !== "undefined" ? globalThis : this);
