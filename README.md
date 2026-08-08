# 人机交互体验设计作品集 — 杨翔

Interaction & experience design portfolio. Self-contained static pages, bilingual (中文 / EN).

- `index.html` — the portfolio page
- `project.html` — a retained draft detail shell; public project actions no longer depend on it
- `resume.html` — the résumé viewer, linked from the site footer
- `portfolio-pdf.html` — the digital-first 16:9 Chinese portfolio source; still being refined, so neither it nor the exported PDF is linked from the site or packaged for deployment
- `assets/` — shared project-page styles and data, figures, screenshots, video, the unpublished `portfolio.pdf`, résumé PDFs, and diagram sources
- `assets/pdf/` — the print-sized image variants used by `portfolio-pdf.html`
- `tools/*/demo/` — route-scoped snapshots of the three interactive tool demos; each keeps its own hashed assets
- `worker/index.mjs` — redirects legacy project paths to their confirmed website, demo, or portfolio-map destination; routes demo paths to their own entry files; and keeps unmatched HTML routes as 404s
- `scripts/build-sites-static.sh` — assembles the deployable `dist/` package
- `scripts/serve-sites-preview.mjs` — runs the real Worker routing against the local package
- `scripts/check-sites-routes.sh` — checks the exact nine-card website/demo/fallback matrix, direct demo rendering, one-hop legacy redirects, and critical assets locally or after deployment; it also guards against the old shared detail routes, `chatgpt.site`, and the unpublished portfolio PDF returning to the homepage
- `scripts/export-portfolio-pdf.sh` — renders `portfolio-pdf.html` to the local `assets/portfolio.pdf` working copy
- `.openai/hosting.json` — identifies the Sites hosting project behind the public custom domain `xiangyang.work`

Design system: Branch Compass v0.7 tokens (light).
