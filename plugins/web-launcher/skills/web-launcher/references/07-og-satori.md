# OG image generation (satori + resvg-js)

*Loaded by `web-launcher` SKILL when generating or updating 1200×630 social cards.*

> **Verified 2026-10-14 · review by 2026-12-13.** Claims that can rot carry their own date and
> source inline. A claim without one has not been checked — treat it as unverified, not as fact.

Ship a raster image (PNG or JPEG). Meta documents a **1200×630** recommendation, a 200×200 minimum,
a 1.91:1 target aspect ratio and an 8 MB file-size ceiling for `og:image`
(verified 2026-10-14 — [Meta: Images in Link Shares](https://developers.facebook.com/documentation/sharing/webmasters/images);
the old `/docs/sharing/webmasters/images/` URL 301s there).

⚠️ **SVG `og:image` does not render on major networks** — this could not be re-verified from a
primary source: Meta's image page documents sizes but not accepted formats (re-checked
2026-10-14), and the X card
reference pages returned 404 on every URL tried on 2026-08-14. Secondary sources agree X accepts
JPG/PNG/WEBP/GIF under 5 MB and not SVG, and they disagree on X's preferred ratio (1.91:1 vs 2:1 vs
16:9). Treat "PNG, 1200×630" as the safe intersection, not as a quoted spec.

## Why satori

- Declarative JSX-style tree → SVG → PNG pipeline
- Native font embedding (no system font dependency at render time)
- Vercel's own OG generator is a wrapper around it: `@vercel/og@1.0.3` declares
  `satori@0.33.5` + `@resvg/resvg-wasm@2.4.1` as its only runtime dependencies
  (verified 2026-10-14 — npm registry metadata for `@vercel/og`)
- Pairs with `@resvg/resvg-js` for SVG→PNG conversion; satori's own README now shows `sharp`
  (librsvg) for that step instead (verified 2026-10-14 — README at `0.56.1`). Either works

**Versions as of 2026-10-14** (npm registry):

| Package | Latest stable | Published | Note |
|---|---|---|---|
| `satori` | 0.56.1 | 2026-10-13 | **23 minor versions in under two weeks**: 0.34.0 (2026-10-02) → 0.56.1, including three breaking layout changes — see "Two paths, two layout engines" below. `0.0.30-beta.1` still sits on the `beta` tag — it is **older** than `latest`, not newer |
| `@resvg/resvg-js` | 2.6.2 | 2024-03-26 | Stable line is over two years old; `2.7.0-alpha.2` (2026-01-28) sits on `next` (dist-tags re-checked 2026-10-14) |
| `@vercel/og` | 1.0.3 | 2026-09-22 | Still pins `satori@0.33.5` — it has not picked up any of the 0.34+ changes |
| `astro-og-canvas` | 0.13.2 | 2026-09-15 | Astro-specific wrapper |

Runtime floors: `satori` still declares `engines.node >= 16` at 0.56.1 and its README states it
runs in the browser, Node ≥ 16 and Web Workers (verified 2026-10-14 — npm metadata and README);
`@resvg/resvg-js` declares `engines.node >= 10` and its README claims Node 12–22 (`engines`
re-checked 2026-09-25 — npm metadata; the README claim still carries its 2026-08-14 stamp).

## Two paths, two layout engines

Which satori you get decides which CSS works, so pick the path first (verified 2026-10-14 —
satori README at tags `0.33.5` and `0.56.1`, GitHub releases, and the commit messages of
[#841](https://github.com/vercel/satori/pull/841), [#847](https://github.com/vercel/satori/pull/847) and
[#855](https://github.com/vercel/satori/pull/855)):

| | `@vercel/og@1.0.3` → satori **0.33.5** | Direct `satori` **0.56.1** |
|---|---|---|
| Layout engine | Yoga | **Taffy** (0.37.0) — flexbox, grid and block layout |
| Default `display` | **`flex`** for every element; a `div` with several children needs `flex`, `contents` or `none` | **Browser defaults** (0.38.1): `div`, `p`, headings and lists are blocks, everything else inline |
| Default `position` | **`relative`** | **`static`** (0.42.0) — insets are ignored on static elements; an absolute child is placed against its nearest positioned ancestor, or the root |
| Default `boxSizing` | **`border-box`** — padding and border sit inside `width`/`height` | **`content-box`** (0.42.0), image sizes included — padding and border are added on top |
| Default `borderStyle` | **`solid`** — a `borderWidth` alone draws a border | **`none`** (0.42.0) — a border without a style is neither drawn nor laid out |
| Grid | Not supported | Supported (0.37.0; shorthands 0.43.0); `subgrid` throws |
| `aspectRatio` | Not in the supported table | Supported (0.39.0) |
| Fonts | TTF, OTF, WOFF — **no WOFF2** | TTF, OTF, WOFF, **WOFF2** (0.55.0) |
| `<style>` stylesheets, `::before`/`::after` | No | Yes (0.51.0, 0.53.0) |

**The 0.38.1 break is silent.** Its release notes list only a performance change; the breaking
change is in commit #847: *"a `div` without `display: flex` no longer lays out its children as
flex items."* 0.37.0's release notes likewise omit the Taffy switch (#841), which also changed
defaults — `flex-shrink` now defaults to 1, flex items don't shrink below their content, top-level
margins are respected. The third break is silent too: 0.42.0's release notes list only a color
change, while #855, first shipped in 0.42.0, is marked *"**Breaking:** `position`, `box-sizing` and
borders use their CSS initial values"* (verified 2026-10-14 — [vercel/satori#855](https://github.com/vercel/satori/pull/855)
and the 0.41.0…0.42.0 compare; the 0.33.5 defaults are from its README's CSS table, `boxSizing`
from the table #849 added just before the switch). The size change is large: a 1200×630 root
with `padding: '80px'` and no `boxSizing` laid out at 1200×630 on 0.33.5 and at **1360×790** on
0.56.1 (rendered 2026-10-14 on both versions). A tree written for 0.33.5 renders differently after
an upgrade. **Set `display: 'flex'` on every container that should be flex, `boxSizing:
'border-box'` on every box with padding or a border, `position: 'relative'` on any container its
absolute children should be placed against, and a `borderStyle` on every border.** The sample
below sets `display` and `boxSizing`, and its boxes landed identically on 0.33.5 and 0.56.1
(rendered 2026-10-14, text omitted). Drop `display` and the paths diverge once the root holds
in-flow children such as the title and tagline divs; drop `boxSizing` and they diverge once a box
gets padding or a border.
Re-check the output after any satori bump.

**Image fetching is guarded.** 0.29.1 hardened satori's SSRF guard: it rejects hostnames that
resolve to private IPs on Node, blocks `.internal` hosts and validates every redirect hop (verified
2026-10-14 — 0.29.1 release notes and commit). Both paths include it. An image URL pointing at a
local dev server or an internal host fails during the build — pass a buffer or a data URI instead.

## Minimum pattern (Node ESM)

```js
import satori from 'satori';
import { Resvg } from '@resvg/resvg-js';
import { readFile, writeFile } from 'node:fs/promises';

// TTF, OTF or WOFF work on both paths; WOFF2 only on direct satori >= 0.55
const fontRoot = 'node_modules/@fontsource';
const plexSans500 = await readFile(`${fontRoot}/ibm-plex-sans/files/ibm-plex-sans-latin-500-normal.woff`);
const plexSans600 = await readFile(`${fontRoot}/ibm-plex-sans/files/ibm-plex-sans-latin-600-normal.woff`);
const plexMono400 = await readFile(`${fontRoot}/ibm-plex-mono/files/ibm-plex-mono-latin-400-normal.woff`);
const instrumentItalic = await readFile(`${fontRoot}/instrument-serif/files/instrument-serif-latin-400-italic.woff`);

const fonts = [
  { name: 'IBM Plex Sans', data: plexSans500, weight: 500, style: 'normal' },
  { name: 'IBM Plex Sans', data: plexSans600, weight: 600, style: 'normal' },
  { name: 'IBM Plex Mono', data: plexMono400, weight: 400, style: 'normal' },
  { name: 'Instrument Serif', data: instrumentItalic, weight: 400, style: 'italic' },
];

const tree = {
  type: 'div',
  props: {
    style: {
      width: '1200px', height: '630px', display: 'flex', boxSizing: 'border-box',
      background: 'linear-gradient(135deg, #0a0b0e 0%, #1e2229 100%)',
      fontFamily: 'IBM Plex Sans', color: '#e7ecf2',
    },
    children: [
      // accent left rule
      { type: 'div', props: { style: { position: 'absolute', top: 0, left: 0, width: '12px', height: '630px', background: '#ffb020', display: 'flex' } } },
      // brand mark as an inline SVG node — no file path to resolve at build time
      {
        type: 'svg',
        props: { width: 72, height: 72, viewBox: '0 0 64 64', style: { position: 'absolute', bottom: '56px', right: '80px' },
          children: [{ type: 'path', props: { d: 'M35 9.85 L42.6 12.31 L29 54.15 L21.4 51.69 Z', fill: '#ffb020' }}]
        }
      },
      // … title + tagline divs …
    ],
  },
};

const svg = await satori(tree, { width: 1200, height: 630, fonts });
const png = new Resvg(svg, { fitTo: { mode: 'width', value: 1200 } }).render().asPng();
await writeFile('./deploy/og-cover.png', png);
```

Both call shapes above are current: `satori(element, options)` with `width` / `height` / `fonts`
(plus `embedFont`, `graphemeImages`, `loadAdditionalAsset`, `debug`, `pointScaleFactor`), and
`new Resvg(svg, opts).render().asPng()` with the `fitTo: { mode, value }` object
(satori options verified 2026-10-14 — [satori README](https://github.com/vercel/satori) at
`0.56.1`; resvg-js verified 2026-08-14 — [resvg-js README](https://github.com/thx/resvg-js)).
Direct satori also takes **`onStyleError`** (0.38.2, [#851](https://github.com/vercel/satori/pull/851)):
without it an invalid or unsupported inline declaration throws and fails the whole render; with it
the declaration is ignored and its error passed to the callback. It is absent from the 0.33.5
README, so the `@vercel/og` path does not have it (verified 2026-10-14 — satori README at both
tags).

## Typographic guidance inside OG

- **Primary display**: Instrument Serif italic (or equivalent) at 96-112px for emotional moments
- **Body / tagline**: IBM Plex Sans 500 at 24-30px
- **Eyebrow / URL**: IBM Plex Mono 400 at 18-22px
- **Color**: accent `#ffb020` exact; body `#e7ecf2`; bg charcoal `#0a0b0e`

## Per-page OG variants

For multi-page sites, parameterize by entry:

```js
function template(entry) {
  return { type: 'div', props: { /* … */ children: [
    /* eyebrow: entry.category */
    /* title: entry.title — font-size = entry.title.length > 28 ? 64 : 76 */
    /* description: entry.description */
    /* footer url: entry.url */
  ]}};
}
```

In Astro, wire up `src/pages/og/[...route].ts`: export a `GET` returning a `Response` whose body is
the PNG buffer with `Content-Type: image/png`, and export `getStaticPaths()` enumerating every
entry. Astro writes the response body out as a static file at build time. If the project's `output`
is server rather than static, add `export const prerender = true` to the endpoint or it renders per
request (verified 2026-08-14 — Astro endpoints + on-demand-rendering docs via Context7,
`/withastro/docs`). Serve it with a long immutable cache.

## Gotchas

- **Font formats** — satori 0.33.5 (the `@vercel/og` path) supports TTF, OTF and WOFF and **not
  WOFF2**; direct satori 0.55.0+ adds WOFF2 (verified 2026-10-14 — satori README at both tags).
  `@fontsource/*` ships `.woff` and `.woff2`; take `.woff` unless you know which path runs. The
  earlier claim in this file that `.ttf` is rejected was wrong.
- **Images are fetched, but only from absolute sources** — satori accepts `props.src` as an HTTP
  URL, a `data:image/…;base64,…` URI, an `ArrayBuffer` or a `Buffer`, and it *will* fetch HTTP URLs.
  There is no base URL, so a relative path resolves to nothing, and private or internal hosts are
  refused (see "Image fetching is guarded" above). Its README recommends base64/buffer data
  anyway, to skip the extra I/O (verified 2026-10-14 — satori README at `0.56.1`). Inline SVG
  nodes, as in the sample above, sidestep the question.
- **Layout engine is a CSS subset, not CSS — and which subset depends on the version.** On 0.33.5
  (`@vercel/og`), `display` accepts `flex`, `block`, `contents`, `none` and `-webkit-box` and
  **defaults to `flex`**; `position` accepts `relative`, `static` and `absolute`, defaulting to
  `relative` (on 0.56.1 it defaults to `static` — see the path table); grid and `aspectRatio` are
  absent. `gap`, `linear-gradient`/`radial-gradient`
  backgrounds, `filter` and `maskImage` are in its supported table. On 0.56.1, properties marked
  "Supported" *"behave as in browsers"*; `display: table`, `ruby` and two-value syntax throw, and
  the table lists the remaining differences (verified 2026-10-14 — satori README CSS table at both
  tags). Check the table for the version you run before reaching for a property.
- **Do not truncate the PNG buffer.** A previous version of this file suggested
  `render().asPng().slice(0, X)` to shrink the file — that cuts a PNG mid-stream and produces a
  corrupt image. To reduce size, re-encode: `sharp`, `oxipng`, or drop to JPEG.
- ⚠️ **Expected file size** — the "~100-150 KB at 1200×630" figure carried by earlier revisions is
  unverified and depends entirely on the artwork (a gradient plus text compresses very differently
  from a photo). Measure the output rather than trusting a number.

## Alternatives — tradeoffs, no default winner

- **satori + `@resvg/resvg-js` (this file)** — smallest dependency surface, native Rust rasterizer,
  runs in any Node build step, framework-agnostic. Cost: you write the layout tree by hand, and the
  rasterizer's stable release has not moved since 2024-03-26.
- **`@vercel/og`** — one `ImageResponse` class over satori, JSX in, `Response` out, targets edge
  runtimes. Cost: an extra abstraction, Vercel-shaped defaults, and an older satori (0.33.5 — the
  implicit-flex layout engine, no grid, no WOFF2; see the path table above); it rasterizes with
  `@resvg/resvg-wasm@2.4.1` (WASM), which is slower than the native binding but portable to runtimes
  with no native addons.
- **`astro-og-canvas`** — declarative config instead of a layout tree, wired into Astro's build.
  Cost: Astro-only, and its template vocabulary is what it is — bespoke layouts fight it.

Pick on runtime and control: native Node build step → satori direct; edge/WASM or an existing
Next.js app → `@vercel/og`; Astro site wanting no layout code → `astro-og-canvas`.

## Verification after deploy

```bash
curl -sI https://DOMAIN/og-cover.png | grep -i content-type  # image/png
curl -sI https://DOMAIN/og-cover.png | grep -i cache-control  # public, max-age=31536000, immutable
```

External validators (see `11-validation-toolkit.md`), reachability checked 2026-08-14:

- https://developers.facebook.com/tools/debug/ — Meta Sharing Debugger, force re-scrape. HTTP 200.
- https://www.linkedin.com/post-inspector/ — LinkedIn preview. HTTP 200.
- https://www.opengraph.xyz/ — paste URL, see rendered card. ⚠️ returned HTTP 429 (rate-limited) on
  the check; the service exists but may throttle automated hits.
- ~~`cards-dev.twitter.com/validator`~~ — **dead for anonymous use**: it 307-redirects to a login
  page (verified 2026-08-14 — `curl -sI`). X publishes no working public card debugger; the only
  reliable check is posting the URL in a draft and reading the preview.

## Skip when

- Coming-soon is one-off, never changes, and a hand-designed static PNG is fine
- Budget doesn't justify Node build tooling — export a PNG from a design tool once
