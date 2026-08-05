const worker = {
  async fetch(request, env) {
    const url = new URL(request.url);
    const assetUrl = new URL(url);

    const projectRoutes = new Set([
      "/projects/digital-me/",
      "/projects/community-hub/",
      "/projects/vibrotactile-platform/",
      "/projects/workzone-safety/",
      "/tools/household-care/",
      "/tools/taskflow/",
      "/tools/workflow-recovery/",
      "/tools/structured-voice-input/",
      "/concepts/synthetic-society/",
    ]);
    const demoRoutes = new Set([
      "/tools/household-care/demo/",
      "/tools/taskflow/demo/",
      "/tools/workflow-recovery/demo/",
    ]);

    // Demo entry files reference their hashed assets relatively, so the slashless
    // form of a route would resolve them against the parent directory. Redirect to
    // the canonical trailing-slash URL before serving anything.
    if (url.pathname !== "/" && !url.pathname.endsWith("/")) {
      const slashPath = `${url.pathname}/`;
      if (projectRoutes.has(slashPath) || demoRoutes.has(slashPath)) {
        const canonicalUrl = new URL(url);
        canonicalUrl.pathname = slashPath;
        return Response.redirect(canonicalUrl.toString(), 308);
      }
    }

    if (assetUrl.pathname === "/") {
      assetUrl.pathname = "/index.html";
    } else if (projectRoutes.has(assetUrl.pathname)) {
      assetUrl.pathname = "/project.html";
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
