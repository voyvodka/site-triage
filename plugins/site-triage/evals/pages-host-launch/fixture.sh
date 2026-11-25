#!/usr/bin/env bash
# A single-page coming-soon site, not yet live, that already deploys through a GitHub Pages workflow.
set -euo pipefail
mkdir -p .github/workflows
cat > coming-soon.html <<'HTML'
<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Lumen — coming soon</title></head><body><h1>Lumen</h1><p>Coming soon.</p></body></html>
HTML
cat > .github/workflows/pages.yml <<'YAML'
name: pages
on: { push: { branches: [main] } }
permissions: { contents: read, pages: write, id-token: write }
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: github-pages
    steps:
      - uses: actions/checkout@v4
      - run: mkdir -p _site && cp coming-soon.html _site/index.html
      - uses: actions/upload-pages-artifact@v3
      - uses: actions/deploy-pages@v4
YAML
