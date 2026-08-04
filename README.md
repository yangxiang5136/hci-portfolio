# 人机交互体验设计作品集 — 杨翔

Interaction & experience design portfolio. Self-contained static pages, bilingual (中文 / EN).

- `index.html` — the portfolio page
- `resume.html` — the résumé viewer, linked from the site footer
- `portfolio-pdf.html` — the digital-first 16:9 Chinese portfolio source
- `assets/` — figures, screenshots, video, résumé PDFs, and the self-contained HTML source for the diagrams that have one
- `assets/pdf/` — the print-sized image variants used by `portfolio-pdf.html`
- `worker/index.mjs` — static asset handler with an `index.html` fallback
- `scripts/build-sites-static.sh` — assembles the deployable `dist/` package
- `scripts/export-portfolio-pdf.sh` — exports the PDF linked from the site footer
- `.openai/hosting.json` — identifies the Sites hosting project behind the public custom domain `xiangyang.work`

Design system: Branch Compass v0.7 tokens (light).
