#!/usr/bin/env node
import { readFile } from "node:fs/promises";

const [modulePath, indexPath] = process.argv.slice(2);
if (!modulePath || !indexPath) {
  console.error("usage: check-demo-language.mjs <portfolio-destination.js> <index.html>");
  process.exit(2);
}

const failures = [];
const expect = (condition, message) => {
  if (!condition) {
    failures.push(message);
  }
};

const moduleSource = await readFile(modulePath, "utf8");
const indexSource = await readFile(indexPath, "utf8");

const scope = {};
new Function("globalThis", moduleSource)(scope);
const resolveDestination = scope.resolvePortfolioDestination;
if (typeof resolveDestination !== "function") {
  console.error("FAIL portfolio-destination.js does not expose resolvePortfolioDestination");
  process.exit(1);
}

// The homepage must actually route its card destinations through the shared
// resolver; otherwise the behaviour below would be asserted on dead code.
expect(
  indexSource.includes('<script src="assets/portfolio-destination.js"></script>'),
  "index.html does not load assets/portfolio-destination.js",
);
expect(
  /resolvePortfolioDestination\(\s*card\.getAttribute\(\s*'data-destination-url'\s*\)\s*,\s*destinationKind\s*,\s*isEn\(\)\s*\?\s*'en'\s*:\s*'zh'\s*,/.test(
    indexSource,
  ),
  "index.html does not resolve card destinations with the active portfolio language",
);

const baseHref = "https://xiangyang.work/";
const cards = indexSource.match(/<article\b[^>]*\bdata-project-id="[^"]*"[^>]*>/g) ?? [];
expect(cards.length === 9, `expected 9 typed project cards in index.html, found ${cards.length}`);

const attribute = (tag, name) => {
  const match = tag.match(new RegExp(`\\b${name}="([^"]*)"`));
  return match ? match[1] : null;
};

const kindCounts = { live: 0, demo: 0, fallback: 0 };
for (const card of cards) {
  const id = attribute(card, "data-project-id");
  const kind = attribute(card, "data-destination-kind");
  const destination = attribute(card, "data-destination-url");
  if (!kind || !destination) {
    failures.push(`card ${id} is missing a destination kind or URL`);
    continue;
  }
  if (kind in kindCounts) {
    kindCounts[kind] += 1;
  } else {
    failures.push(`card ${id} declares the unknown destination kind ${kind}`);
    continue;
  }

  if (kind === "demo") {
    for (const language of ["zh", "en"]) {
      const resolved = resolveDestination(destination, kind, language, baseHref);
      expect(
        resolved === `${destination}?lang=${language}`,
        `card ${id} resolves to ${resolved} in ${language}, expected ${destination}?lang=${language}`,
      );
    }
    const unknownLanguage = resolveDestination(destination, kind, "fr", baseHref);
    expect(
      unknownLanguage === `${destination}?lang=zh`,
      `card ${id} does not fall back to Chinese for an unknown language, got ${unknownLanguage}`,
    );
  } else {
    for (const language of ["zh", "en"]) {
      const resolved = resolveDestination(destination, kind, language, baseHref);
      expect(
        resolved === destination,
        `card ${id} is a ${kind} destination but ${language} rewrote it to ${resolved}`,
      );
    }
  }
}

expect(kindCounts.live === 2, `expected 2 live cards, found ${kindCounts.live}`);
expect(kindCounts.demo === 3, `expected 3 demo cards, found ${kindCounts.demo}`);
expect(kindCounts.fallback === 4, `expected 4 fallback cards, found ${kindCounts.fallback}`);

if (failures.length > 0) {
  for (const failure of failures) {
    console.error(`FAIL ${failure}`);
  }
  process.exit(1);
}

console.log("ok  homepage demo cards carry the active portfolio language into their demo URL");
