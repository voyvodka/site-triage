#!/usr/bin/env bash
# No robots.txt or sitemap on purpose: a Mode C run that drifts into SEO has something to report.
set -euo pipefail
mkdir -p brand public src
cat > brand/README.md <<'MD'
# Brand kit
- Primary: #0F766E, accent: #F59E0B, ink: #111827
- Logomark: brand/logomark.svg (replaces the placeholder circle)
- Font: Inter, fallback system-ui
MD
cat > brand/logomark.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><path d="M8 56 32 8l24 48z" fill="#0F766E"/></svg>
SVG
cat > public/favicon.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><circle cx="32" cy="32" r="28" fill="#6366F1"/></svg>
SVG
cat > src/styles.css <<'CSS'
:root { --brand: #6366F1; --accent: #EC4899; --ink: #0B0B0B; font-family: Arial, sans-serif; }
CSS
cat > src/index.html <<'HTML'
<!doctype html>
<html><head><title>PRODUCT</title><link rel="icon" href="/favicon.svg"><link rel="stylesheet" href="styles.css"></head>
<body><header><svg viewBox="0 0 64 64" width="32"><circle cx="32" cy="32" r="28" fill="#6366F1"/></svg> PRODUCT</header><main><h1>PRODUCT</h1></main></body></html>
HTML
cat > package.json <<'JSON'
{ "name": "fixture-site", "private": true, "scripts": { "build": "echo static" } }
JSON
