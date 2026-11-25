#!/usr/bin/env bash
# Deployed on Vercel, with no robots.txt or sitemap, so the gap report has real work to rank.
set -euo pipefail
mkdir -p src/pages public
cat > package.json <<'JSON'
{ "name": "fixture-site", "private": true, "scripts": { "build": "astro build" }, "dependencies": { "astro": "^5.0.0" } }
JSON
cat > astro.config.mjs <<'JS'
import { defineConfig } from 'astro/config';
export default defineConfig({ site: 'https://DOMAIN' });
JS
cat > vercel.json <<'JSON'
{ "cleanUrls": true, "headers": [{ "source": "/(.*)", "headers": [{ "key": "X-Content-Type-Options", "value": "nosniff" }] }] }
JSON
cat > src/pages/index.astro <<'HTML'
<html lang="en"><head><title>PRODUCT</title></head><body><h1>PRODUCT</h1></body></html>
HTML
cat > src/pages/docs.astro <<'HTML'
<html lang="en"><head><title>Docs</title></head><body><h1>Docs</h1></body></html>
HTML
