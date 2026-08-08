const worker = {
  async fetch(request, env) {
    const url = new URL(request.url);
    const assetUrl = new URL(url);

    const legacyProjectRedirects = new Map([
      ["/projects/digital-me/", "https://digital-me-dashboard.vercel.app/"],
      ["/projects/community-hub/", "https://blacksburg-secondhand-production.up.railway.app/"],
      ["/projects/vibrotactile-platform/", "/#atlas"],
      ["/projects/workzone-safety/", "/#atlas"],
      ["/tools/household-care/", "/tools/household-care/demo/?lang=zh"],
      ["/tools/taskflow/", "/tools/taskflow/demo/?lang=zh"],
      ["/tools/workflow-recovery/", "/tools/workflow-recovery/demo/?lang=zh"],
      ["/tools/structured-voice-input/", "/#atlas"],
      ["/concepts/synthetic-society/", "/#atlas"],
    ]);
    const demoRoutes = new Set([
      "/tools/household-care/demo/",
      "/tools/taskflow/demo/",
      "/tools/workflow-recovery/demo/",
    ]);

    const legacyPath = url.pathname.endsWith("/") ? url.pathname : `${url.pathname}/`;
    const legacyTarget = legacyProjectRedirects.get(legacyPath);
    if (legacyTarget) {
      const destination = new URL(legacyTarget, url);
      if (destination.pathname.includes("/demo/")) {
        const requestedLanguage = url.searchParams.get("lang");
        if (requestedLanguage === "en" || requestedLanguage === "zh") {
          destination.searchParams.set("lang", requestedLanguage);
        }
      }
      // Temporary, so a future destination change is not pinned in browser caches.
      return Response.redirect(destination.toString(), 307);
    }

    // Demo entry files reference their hashed assets relatively, so the slashless
    // form of a route would resolve them against the parent directory. Redirect to
    // the canonical trailing-slash URL before serving anything.
    if (url.pathname !== "/" && !url.pathname.endsWith("/")) {
      const slashPath = `${url.pathname}/`;
      if (demoRoutes.has(slashPath)) {
        const canonicalUrl = new URL(url);
        canonicalUrl.pathname = slashPath;
        return Response.redirect(canonicalUrl.toString(), 308);
      }
    }

    if (assetUrl.pathname === "/") {
      assetUrl.pathname = "/index.html";
    } else if (demoRoutes.has(assetUrl.pathname)) {
      assetUrl.pathname = `${assetUrl.pathname}index.html`;
    }

    const response = await env.ASSETS.fetch(new Request(assetUrl, request));
    if (response.status !== 404 || !request.headers.get("accept")?.includes("text/html")) {
      return response;
    }

    // Serve the portfolio shell for unmatched HTML routes, but keep the 404 status so
    // crawlers and monitoring do not record a missing page as a successful one.
    const fallbackUrl = new URL("/index.html", request.url);
    const fallback = await env.ASSETS.fetch(new Request(fallbackUrl, request));
    if (!fallback.ok) {
      return fallback;
    }
    return new Response(fallback.body, {
      status: 404,
      statusText: "Not Found",
      headers: fallback.headers,
    });
  },
};

export default worker;
