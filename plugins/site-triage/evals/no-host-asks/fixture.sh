#!/usr/bin/env bash
# A fresh static site with no deploy config and no host chosen.
set -euo pipefail
mkdir -p src/pages public
cat > package.json <<'JSON'
{ "name": "fixture-site", "private": true, "scripts": { "build": "astro build" }, "dependencies": { "astro": "^5.0.0" } }
JSON
cat > src/pages/index.astro <<'HTML'
<html lang="en"><head><title>PRODUCT</title></head><body><h1>PRODUCT</h1></body></html>
HTML
