const worker = {
  async fetch(request, env) {
    const url = new URL(request.url);
    const assetUrl = new URL(url);

    if (assetUrl.pathname === "/") {
      assetUrl.pathname = "/index.html";
    }

    const response = await env.ASSETS.fetch(new Request(assetUrl, request));
    if (response.status !== 404 || !request.headers.get("accept")?.includes("text/html")) {
      return response;
    }

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
