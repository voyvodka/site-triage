# Coming-soon / landing page scaffolding

*Loaded by `web-launcher` SKILL when user wants a single-page coming-soon / landing HTML in Mode A.*

> **Verified 2026-10-14 · review by 2026-12-13.** Claims that can rot carry their own date and
> source inline. A claim without one has not been checked — treat it as unverified, not as fact.

## Structure

Single-file HTML, everything inlined. Zero build step, zero external CSS, at most one webfont
`<link>`.

```
coming-soon.html           ← authoring file (lives in project root)
```

Deploy folder after build (or direct upload):
```
deploy/
├── index.html             ← renamed coming-soon.html
├── favicon.svg
├── favicon.ico            ← fallback for browsers without SVG favicons (see 01)
├── apple-touch-icon.png   ← 180×180 PNG, opaque (Apple documents PNG only)
├── og-cover.png           ← generated via satori (see 07-og-satori.md)
├── robots.txt
├── sitemap.xml
├── llms.txt
├── humans.txt
├── _headers               ← CF security + cache
└── .well-known/
    └── security.txt
```

`_headers` is valid for Cloudflare Workers static assets — place it in the assets directory, up to
100 rules, 2,000 characters per line. It applies to static asset responses only, **not** to
responses your Worker code generates (verified 2026-10-14 —
[Workers static assets headers](https://developers.cloudflare.com/workers/static-assets/headers/), page last updated 2026-09-22).

## HTML skeleton

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover" />
<title>PRODUCT — Launching soon</title>
<meta name="description" content="…tagline + what it does + open-source/launch note…" />
<link rel="canonical" href="https://DOMAIN/" />
<meta name="color-scheme" content="dark light" />
<meta name="theme-color" media="(prefers-color-scheme: light)" content="#ffffff" />
<meta name="theme-color" media="(prefers-color-scheme: dark)" content="#0a0b0e" />
<link rel="icon" href="/favicon.ico" sizes="32x32" />
<link rel="icon" href="/favicon.svg" type="image/svg+xml" sizes="any" />
<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
<!-- full meta + OG + twitter + JSON-LD: see 03-discoverability-classic.md -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<!-- One request, every family the Typography section below uses. Loading only PRIMARY_FONT
     leaves the <em> in the H1 and the mono eyebrow falling back to system fonts. -->
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&family=Instrument+Serif:ital@1&display=swap" rel="stylesheet">
<style>
  /* Inline CSS — everything the page needs */
  :focus-visible { outline: 2px solid #ACCENT; outline-offset: 3px; }
  @media (prefers-reduced-motion: reduce) {
    .pulse, .animated { animation: none; }
  }
</style>
</head>
<body>
  <main>
    <p class="brand-anchor">
      <svg viewBox="0 0 64 64" width="20" height="20" aria-hidden="true">
        <path d="…LOGOMARK PATH…" fill="#ACCENT"></path>
      </svg>
      <span>PRODUCT</span>
    </p>
    <p class="eyebrow">Launching soon</p>
    <h1>PRODUCT is <em>almost here.</em></h1>
    <p class="lede">Tagline sentence. Open source. What it does.</p>
    <div class="actions">
      <a class="btn primary" href="REPO_URL">View the source</a>
      <a class="btn ghost" href="RELEASES_URL">Latest release</a>
    </div>
    <p class="meta"><span>macOS</span><span>·</span><span>Windows</span><span>·</span><span>Linux</span></p>
    <footer>© YEAR NAME · <a href="REPO_URL">Source</a></footer>
  </main>
</body>
</html>
```

### What changed in the head, and why

- **`<meta name="robots" content="index,follow">` removed.** It states the default. Google
  documents `all` — "no restrictions for indexing or serving" — as "the default value and has no
  effect if explicitly listed", and says a page may be indexed and its links followed when neither
  `noindex` nor `nofollow` is specified (verified 2026-10-14 —
  [Google robots meta tag docs](https://developers.google.com/search/docs/crawling-indexing/robots-meta-tag), page last updated 2026-03-24).
  Write a robots meta tag only when the value is *not* the default (a staging page wanting
  `noindex`, for example).
- **`rel="apple-touch-icon"` now points at a PNG, not the SVG.** Apple's web-content docs specify
  a PNG file and never an SVG; one opaque 180×180 file covers current iOS devices. What iOS does
  with a non-PNG href, and the often-repeated "transparency turns black", have no primary source —
  `01-brand-application.md` carries the sourced version and the caveats. Ship an opaque PNG and
  verify on a device. MDN lists `apple-touch-icon` as a non-standard `rel` value, which is
  expected — it is Apple's.
- **`favicon.ico` alongside the SVG.** SVG favicons reach Safari only from 26.0 (verified
  2026-10-14 — [WebKit, Safari 26.0 features](https://webkit.org/blog/17333/webkit-features-in-safari-26-0/):
  "now supports the SVG file format for icons … including favicons"); the ICO covers the rest
  (`01-brand-application.md`, icon set). The ICO is also the file Google Search can use: its
  favicon formats are BMP, GIF, ICO, PNG, JPEG, PPM and TIFF — no SVG — with larger than 48×48
  recommended (verified 2026-10-14 —
  [Favicon in Google Search](https://developers.google.com/search/docs/appearance/favicon-in-search),
  page last updated 2026-08-28). Add `site.webmanifest` and the icons it lists from the same file
  if the page should be installable.
- **`rel="mask-icon"` dropped.** Safari-only, for macOS pinned tabs, and absent from MDN's `rel`
  value list entirely (verified 2026-10-14 against the mdn/content source —
  [MDN rel attribute](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/rel)).
  Harmless if kept; it buys one browser surface and costs a monochrome SVG export.
- **`theme-color` split by `prefers-color-scheme`.** Where the tag is used, the HTML spec picks
  the first `theme-color` meta in tree order whose `media` matches and whose `content` parses as a
  colour (verified 2026-10-14 —
  [HTML spec, obtaining a page's theme color](https://html.spec.whatwg.org/multipage/semantics.html#meta-theme-color)),
  so a light/dark pair follows the user's scheme. Where it is used is now narrow. Per
  browser-compat-data (verified 2026-10-14 —
  [BCD `meta` name `theme-color`](https://github.com/mdn/browser-compat-data/blob/main/html/elements/meta.json),
  surfaced on [MDN theme-color](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/meta/name/theme-color)):
  Safari from 15, but **from Safari 26 only for installed web apps** (BCD mirrors the Safari data
  to iOS, so the same applies there); Chrome desktop from 73, **installed PWAs only**; Chrome on
  Android from 92 in the browser itself; Firefox not at all. Neither Apple's Safari 26.0 release notes
  nor WebKit's Safari 26.0 feature post mention the change (both read 2026-10-14), so BCD is the
  best source there is. In practice: keep the pair — it is cheap and correct for installed apps and
  Android Chrome — but do not promise a coloured browser bar in a desktop or iOS Safari tab, and
  make the page's own top background carry the look.
- **`rel="canonical"` added.** A coming-soon page is exactly the kind of URL that gets reached with
  campaign parameters and both host spellings; one self-referential canonical settles it.
- **`color-scheme` added.** Tells the UA to render form controls, scrollbars and the default
  background in the right scheme instead of flashing white.

### Webfont link: the tradeoff

The `<link>` to a font CDN is render-blocking and adds a third-party origin to the critical path;
`preconnect` shaves the handshake but does not remove the dependency. Self-hosting the `.woff2`
next to the HTML removes the origin and lets you `preload` the file — but web.dev's own guidance is
that in practice the measured difference between the two is "less clear cut" than the theory
suggests (verified 2026-10-14 — [web.dev font best practices](https://web.dev/articles/font-best-practices); the article itself was last updated 2022-10-04, so treat it as old guidance that has not been revised, not as a fresh measurement).
For a single-page coming-soon, the honest answer is that either works; self-host if the page must
also avoid handing visitor IPs to a third party.

## Must-haves

- **Single `<h1>`** — states the launching-soon fact
- **`<main>` landmark** wrapping content, `<footer>` at bottom
- **`brand-anchor`** at top-left (mark + wordmark) — identity anchor
- **Platform / stack row** — builds credibility fast
- **CTAs** to the repository + latest release (leverage existing launch funnel)
- **`prefers-reduced-motion`** override for any pulse / animation
- **Visible focus ring** — a `:focus-visible` rule, since a dark theme plus a custom `.btn` often
  erases the UA default and leaves keyboard users with no indication of position
- **Accessible names on icon-only links** — decorative SVGs get `aria-hidden="true"` (as above); any
  link whose only content is an icon needs an `aria-label`
- **JSON-LD structured data** in `<head>`:
  - `WebSite`
  - `SoftwareApplication` (if a product launch)
  - `Organization` with `logo` absolute URL
  - See `03-discoverability-classic.md` for exact template

## Layout gotcha

If both `brand-anchor` and eyebrow are `<p>` with `display: inline-flex`, they flow onto the same
line. Fix: `.brand-anchor { display: flex; width: fit-content; }` (block-level flex). Observed in
practice, not sourced — it is plain flow behaviour, verify it in the browser rather than trusting
the note.

## Typography rules (default)

- `body` font: IBM Plex Sans 500 (or brand primary)
- Eyebrow / meta / monospace: IBM Plex Mono 400/500
- Display / hero italic accent: Instrument Serif italic (sparingly — in H1 `<em>` only)
- Colors: body `#e7ecf2`, background `#0a0b0e`, accent `#ffb020` (exact, no tints)

Check the accent against its background for WCAG contrast before shipping — an amber-on-charcoal
pair passes for large text far more easily than for 14px body copy, and the eyebrow/meta row is the
usual casualty.

## Deploy checklist

Before shipping to CF Workers:
1. Copy `coming-soon.html` → `deploy/index.html`
2. Generate `deploy/og-cover.png` via satori (see `07-og-satori.md`) and export
   `deploy/apple-touch-icon.png` at 180×180, opaque, plus `deploy/favicon.ico`
3. Write `deploy/robots.txt`, `deploy/sitemap.xml`, `deploy/llms.txt`, `deploy/humans.txt`,
   `deploy/_headers`, `deploy/.well-known/security.txt` (see `03-discoverability-classic.md` +
   `06-agent-ready.md`)
4. `wrangler deploy` (see `08-cloudflare-deploy.md`)
