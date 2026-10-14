# Cloudflare Workers deployment (wrangler + static assets + zone settings)

*Loaded by `web-launcher` SKILL for Mode A deploy phase, or Mode B when changing infrastructure.*

> **Verified 2026-10-14 · review by 2026-12-13.** Claims that can rot carry their own date and
> source inline. A claim without one has not been checked — treat it as unverified, not as fact.

## Platform choice: Workers Static Assets

Deploy static sites as a Worker with an `assets` directory. Cloudflare documents `_headers` and
`_redirects` as natively supported here, and publishes a Pages → Workers migration guide stating
"Unlike Pages, Workers has a distinctly broader set of features available to it"
(verified 2026-10-14 — [Migrate from Pages to Workers](https://developers.cloudflare.com/workers/static-assets/migration-guides/migrate-from-pages/), page last updated 2026-10-12).

Cloudflare now steers new projects away from Pages, without deprecating it. The Pages landing page
opens with "Are you sure you want to use Pages?" and "Workers supports most Pages use cases and
offers a broader feature set … Start new projects with Workers"
(verified 2026-10-14 — [Cloudflare Pages](https://developers.cloudflare.com/pages/), page last updated 2026-08-25),
and C3 (`npm create cloudflare`) "will always create a Workers project" unless `--platform=pages`
is passed (verified 2026-10-14 — [C3 CLI](https://developers.cloudflare.com/pages/get-started/c3/)).
⚠️ Neither page says Pages is deprecated or closed. Do not tell users Pages is going away; say that
Cloudflare recommends Workers for new projects and that a migration guide exists. (The docs *do*
say "Do not use Workers Sites for new projects" — that is the older `[site]` product, not Pages.)

## Baseline `wrangler.jsonc`

```jsonc
{
  "$schema": "./node_modules/wrangler/config-schema.json",
  "name": "PROJECT",
  "compatibility_date": "YYYY-MM-DD",
  "assets": {
    "directory": "./deploy",
    "binding": "ASSETS",
    "not_found_handling": "single-page-application"   // ONLY for a real single-page app — see below
  },
  "routes": [
    { "pattern": "DOMAIN", "custom_domain": true }
  ]
}
```

Field notes (verified 2026-10-14 — [Wrangler configuration](https://developers.cloudflare.com/workers/wrangler/configuration/)):

| Field | Today's behaviour |
|---|---|
| `$schema` | Docs use the local path `./node_modules/wrangler/config-schema.json`. `https://unpkg.com/wrangler/config-schema.json` still resolves (302 → 200, checked 2026-10-14) but the local path is what the docs show |
| `compatibility_date` | Required, `yyyy-mm-dd`. Set to the day you scaffold |
| `assets.directory` | Folder of static assets to serve |
| `assets.binding` | Only needed if a Worker script calls `env.ASSETS.fetch()`. A purely static site needs no `main` and no binding |
| `assets.not_found_handling` | `"single-page-application"` \| `"404-page"` \| `"none"` — **default `"none"`**. Pick from the shape found in SKILL.md scan step 2, do not copy the baseline blindly: `"single-page-application"` only for a client-routed SPA, `"404-page"` for a multi-page site (docs, blog, marketing subpages) that ships a `404.html`, `"none"` otherwise. On a multi-page site the SPA value turns every mistyped or removed route into a **200 serving the homepage** — a soft 404. Google reports those as "Duplicate without user-selected canonical" or indexes the homepage under the wrong URL, and `14-diagnostic-checks.md` C1 will not flag it either, because the response genuinely is 200. |
| `assets.html_handling` | `"auto-trailing-slash"` (default) \| `"force-trailing-slash"` \| `"drop-trailing-slash"` \| `"none"` |
| `assets.run_worker_first` | `boolean` (default `false`) or an array of route patterns with `*` globs and `!` exceptions. Every pattern must begin with `/` or `!/`; at most 100 entries, duplicates included. The array form arrived in Wrangler 4.20.0 (verified 2026-10-14 — [wrangler@4.20.0 release notes](https://github.com/cloudflare/workers-sdk/releases/tag/wrangler%404.20.0)) |
| `routes[].custom_domain` | `true` → Cloudflare creates the DNS records and issues certificates for you |
| `workers_dev` | Defaults to `true` when there are no `route`/`routes`, `false` otherwise — see the gotcha below |
| `preview_urls` | `boolean`. Turns Version URLs and `workers.dev` Preview URLs on or off. If omitted, Wrangler leaves an existing setting alone; with no setting at all, the initial value follows `workers_dev` |

## Routing order — read this before adding a Worker script

> "By default, if a requested URL matches a file in the static assets directory, that file will be
> served — without invoking Worker code. If no matching asset is found and a Worker script is
> present, the request will be processed by the Worker."
> (verified 2026-10-14 — [Static Assets](https://developers.cloudflare.com/workers/static-assets/))

Consequence: **a Worker script does not see requests that match an asset.** Any Worker logic meant
to run on every request (host redirects, header injection, auth) silently does nothing on `/`,
`/about/`, `/favicon.svg` and every other real file. It only fires on misses — which is exactly why
a random-path smoke test passes while the homepage does not.

To run the Worker ahead of asset serving, set `assets.run_worker_first: true`, or an array of
patterns for selective control
(verified 2026-10-14 — [Routing / Worker script](https://developers.cloudflare.com/workers/static-assets/routing/worker-script/)).

A second mechanism moves the same line and is easy to miss. The compatibility flag
**`assets_navigation_prefers_asset_serving`**, default since **2025-04-01**, makes navigation
requests (`Sec-Fetch-Mode: navigate`) prefer asset serving *even when no asset matches exactly* —
so SPA and custom-404 fallbacks are served ahead of the Worker. Without it the old behaviour
applies and a miss invokes the Worker. **`run_worker_first: true` overrides the flag entirely**
(verified 2026-10-14 — [Compatibility flags](https://developers.cloudflare.com/workers/configuration/compatibility-flags/)).

Consequence when debugging "my Worker does not run": check the compatibility date as well as
`run_worker_first`. A project scaffolded after April 2025 inherits the flag silently.

> **Verify before you rely on a key here.** This is the fastest-moving reference in this skill. If
> this session can reach Cloudflare's documentation directly — a Cloudflare docs MCP server, or any
> documentation tool — query it for the specific field before recommending it, and cite what came
> back. It is a search, not an oracle: a query that returns nothing relevant leaves the claim
> unverified, it does not confirm it. Nothing here depends on that tool being present.

## www → apex redirect

**Recommended: a zone-level redirect rule, not a Worker.** Cloudflare's own Custom Domains page
documents this:

> "Because Custom Domains require an exact hostname match, a Worker attached to `example.com` will
> not receive requests sent to `www.example.com`, and vice versa. To make both versions of your
> domain work, set up a redirect rule … You also need a proxied DNS record for the hostname you are
> redirecting from … Add a proxied DNS A record for `www` pointing to `192.0.2.0`, or a proxied AAAA
> record pointing to `100::`"
> (verified 2026-10-14 — [Custom Domains](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/), page last updated 2026-09-29)

`192.0.2.0` / `100::` are documented reserved placeholders for originless setups; the record is
proxied, so the request never leaves Cloudflare. Steps for the user, in the dashboard:
`DOMAIN → DNS → Records` (add proxied `www` A record `192.0.2.0`), then
`DOMAIN → Rules → Redirect Rules` (source `www.DOMAIN`, target apex, 301, preserve path + query).
The Pages equivalent guide uses Bulk Redirects with the same DNS trick
(verified 2026-10-14 — [Redirecting www to domain apex](https://developers.cloudflare.com/pages/how-to/www-redirect/)).

**The linked example rule matches HTTPS only.** Cloudflare's "Redirect from WWW to root" example
uses the request URL `https://www.*` and lists `http://www.example.com/?all_items=true` as
"(unchanged)" (verified 2026-10-14 — [Redirect from WWW to root](https://developers.cloudflare.com/rules/url-forwarding/examples/redirect-www-to-root/), page last updated 2026-05-05).
Copied as-is, `http://www.DOMAIN/` therefore takes two hops: Always Use HTTPS sends it to
`https://www.DOMAIN/`, then the rule sends it to the apex. Google's crawlers follow up to 10
redirect hops by default (verified 2026-10-14 —
[HTTP status codes and Google crawlers](https://developers.google.com/crawling/docs/troubleshooting/http-status-codes)),
so two hops costs nothing in indexing. If you want one anyway, widen the match to `http*://www.*` — the documented wildcard form for "either
scheme" (verified 2026-10-14 — [Create a redirect rule](https://developers.cloudflare.com/rules/url-forwarding/single-redirects/create-dashboard/)) —
and set the target to `https://${2}`: captures are numbered left to right, one per `*`, so the
scheme suffix is now `${1}` (verified 2026-10-14 — `wildcard_replace` examples in
[Rules language functions](https://developers.cloudflare.com/ruleset-engine/rules-language/functions/)).
The verification block below probes the `http://` leg either way.

Redirect status codes differ by mechanism (verified 2026-10-14):
- **Single Redirects** (Redirect Rules) and **Bulk Redirects**: 301, 302, 307 or 308, **default 301**
  ([Single Redirects settings](https://developers.cloudflare.com/rules/url-forwarding/single-redirects/settings/),
  [Bulk Redirects parameters](https://developers.cloudflare.com/rules/url-forwarding/bulk-redirects/reference/parameters/)).
- **`_redirects`** in the asset directory: 301, 302, 303, 307 or 308, **default 302**, and no
  domain-level rules — it cannot do www → apex at all
  ([Redirects](https://developers.cloudflare.com/workers/static-assets/redirects/)).

**Worker variant** — only if the user cannot or will not touch zone rules. It requires *both*
`www.DOMAIN` as a custom domain *and* `run_worker_first`, otherwise it never fires (see routing
order above):

```jsonc
{
  "main": "./src/worker.js",
  "assets": {
    "directory": "./deploy",
    "binding": "ASSETS",
    "not_found_handling": "404-page",   // same choice as the baseline — pick per site shape
    "run_worker_first": true
  },
  "routes": [
    { "pattern": "DOMAIN", "custom_domain": true },
    { "pattern": "www.DOMAIN", "custom_domain": true }
  ]
}
```

```js
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.hostname === 'www.DOMAIN') {
      url.hostname = 'DOMAIN';
      return Response.redirect(url.toString(), 301);
    }
    return env.ASSETS.fetch(request);
  },
};
```

**Cost of this variant:** the docs warn that with `run_worker_first` configured "you will likely need
to attach any custom headers you wish to apply directly within that Worker script", because
`_headers` rules "are not applied to responses generated by your Worker code"
(verified 2026-10-14 — [Headers](https://developers.cloudflare.com/workers/static-assets/headers/)).
⚠️ Whether a response returned straight from `env.ASSETS.fetch()` still picks up `_headers` is not
stated either way in the docs — untested here. If you take this route, verify the security headers
are present on a real page (`curl -sI https://DOMAIN/`) before calling the deploy done, and be ready
to set them in Worker code instead. The redirect-rule approach avoids the question entirely.

## `_headers` — security + caching

Place in `deploy/_headers` (the asset directory root). Limits: 100 rules per file, 2,000 characters
per line (verified 2026-10-14 — [Headers](https://developers.cloudflare.com/workers/static-assets/headers/), page last updated 2026-09-22).

```
/*
  Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  X-Frame-Options: DENY
  Content-Security-Policy: default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; script-src 'self'; img-src 'self' data:; base-uri 'self'; frame-ancestors 'none'; form-action 'self'
  Link: </llms.txt>; rel="describedby", </sitemap.xml>; rel="sitemap", </.well-known/security.txt>; rel="security-txt"

/og-cover.png
  Cache-Control: public, max-age=31536000, immutable

/favicon.svg
  Cache-Control: public, max-age=604800
```

Notes:
- **`Permissions-Policy` no longer carries an ad-tracking opt-out.** `interest-cohort=()` (FLoC)
  is absent from MDN's directive list and from browser-compat-data, and `browsing-topics=()` (Topics API), which this
  baseline used to ship, is now marked **deprecated and non-standard** on MDN and in
  browser-compat-data, Chrome 115+ only (verified 2026-10-14 —
  [MDN Permissions-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Permissions-Policy),
  [MDN browsing-topics](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Permissions-Policy/browsing-topics),
  [BCD Permissions-Policy](https://github.com/mdn/browser-compat-data/blob/main/http/headers/Permissions-Policy.json)).
  Nothing replaces either. The line above now denies three standard-track features a static page
  never uses — `camera`, `microphone`, `geolocation` — so an injected or third-party script cannot
  prompt for them. Two limits: BCD records the header itself as Chromium-only (Chrome 85+; Firefox
  and Safari do not implement it) and experimental, so this is defence in depth, not a control
  every visitor gets; and if the site genuinely uses one of these features, drop it from the list.
  Sites still shipping `interest-cohort=()` (read by nothing) or `browsing-topics=()` (deprecated)
  should drop them rather than carry them forward.
- **`'unsafe-inline'` in `script-src` is not needed for JSON-LD, and the baseline above does not
  carry it.** `style-src` keeps it for the inline `<style>` block the scaffold ships. A
  `<script type="application/ld+json">` block is a *data block*: the
  HTML spec's "prepare the script element" algorithm returns at the type-matching step
  ("Otherwise, return. (No script is executed, and el's type is left as null.)") long before it
  reaches the CSP inline check further down the same algorithm (verified 2026-10-14 —
  [HTML spec, prepare the script element](https://html.spec.whatwg.org/multipage/scripting.html#prepare-the-script-element)).
  Structured data works under `script-src 'self'` with no exception at all.

  Drop `'unsafe-inline'` unless the site has real inline JavaScript. Keeping it "for JSON-LD" buys
  nothing and leaves the door open for the next contributor's inline handler. If Bot Fight Mode is
  turned on, Cloudflare injects challenge scripts and its own docs "highly discourage the use of
  `unsafe-inline`", recommending nonces instead (see zone settings below) — so that branch does not
  justify it either.
- Google Fonts requires explicit `fonts.googleapis.com` (style) + `fonts.gstatic.com` (font).
- To keep the free `workers.dev` URL out of search results, the docs give this rule
  (verified 2026-10-14 — same page):
  ```
  https://:version.:subdomain.workers.dev/*
    X-Robots-Tag: noindex
  ```

Default headers Workers already attaches to static assets, so do not re-declare them:
`Content-Type`, `ETag`, `CF-Cache-Status`, and
`Cache-Control: public, max-age=0, must-revalidate` — which the docs describe as ensuring "stale
content will never be served" (verified 2026-10-14 — same page).

## `_redirects`

Same directory, one rule per line, `[source] [destination] [code?]`. Codes 301, 302, 303, 307 and
308 are supported and the default is **302**; domain-level rules (`www.DOMAIN/* …`) are not, so
host redirects belong in a zone rule. Limits: 2,000 static + 100 dynamic redirects (2,100 total),
1,000 characters per declaration. Order matters — the top-most match wins, and static rules must
precede dynamic ones. Redirects "are not applied to requests served by your Worker code"
(verified 2026-10-14 — [Redirects](https://developers.cloudflare.com/workers/static-assets/redirects/), page last updated 2026-08-25).
Past 2,100 rules, the docs point to Bulk Redirects.

## Deploy sequence

Latest wrangler at time of writing: **4.151.0**, published 2026-10-14
(verified 2026-10-14 — `npm view wrangler dist-tags.latest`).

```bash
# 1. Login once (interactive OAuth)
npx wrangler@latest login          # --use-keyring: keep the credentials encrypted, key in the OS keychain
                                   # --device: no localhost callback (SSH, containers, remote shells)

# 2. Verify
npx wrangler@latest whoami

# 3. Deploy (uploads assets + script + registers custom domains)
npx wrangler@latest deploy
```

Login options (verified 2026-10-14 — [Wrangler general commands](https://developers.cloudflare.com/workers/wrangler/commands/general/)):
- **`--use-keyring`** does not put the tokens themselves in the keychain. Wrangler writes them to
  an AES-256-GCM-encrypted file (`default.enc`, next to the old `default.toml`) and stores only the
  32-byte encryption key in the OS keychain. The choice persists across invocations;
  `--no-use-keyring` opts back out. Without it, tokens sit in a plaintext TOML file.
- **`--device`** uses the OAuth device authorization grant (RFC 8628): Wrangler prints a URL and a
  short code and polls, so no local callback server is needed. It cannot be combined with
  `--callback-host` / `--callback-port`.
- **Optional scopes.** The consent dialog now lets you untick optional scopes instead of granting
  everything; a command that needs a declined scope fails until you re-authorize (verified
  2026-10-14 — [changelog 2026-08-22](https://developers.cloudflare.com/changelog/post/2026-08-22-wrangler-mcp-optional-oauth-scopes/)).
  Named auth profiles (`--profile`) cover working across several accounts.

`login`, `whoami` and `deploy` are all current; the command reference is split —
`login`/`whoami` under
[general commands](https://developers.cloudflare.com/workers/wrangler/commands/general/) and `deploy`
under [Workers commands](https://developers.cloudflare.com/workers/wrangler/commands/workers/)
(verified 2026-10-14).

Expected output names the uploaded file count and the registered triggers. ⚠️ Do not pattern-match
the exact wording — Wrangler ships several times a week (25 stable releases between 2026-09-14 and
2026-10-14, 4.131.2 → 4.151.0, npm registry `time` field read 2026-10-14) and the output format is
not a documented contract. Assert on `curl` results instead.

Custom domains create the DNS records and issue certificates automatically; the docs note this
generates an **Advanced Certificate** on the zone, and that deleting the custom domain does *not*
delete that certificate — it must be removed by hand under SSL/TLS → Edge Certificates
(verified 2026-10-14 — [Custom Domains](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/)).

### Other paths, and what is new

Wrangler from a terminal stays the path this skill documents. Know the alternatives exist
(all verified 2026-10-14):

- **Workers Builds** — connect the repository in the dashboard and Cloudflare builds and deploys on
  push; builds on non-production branches create a Preview and can post its URL to the pull
  request, now "within a few seconds" of the build finishing
  ([Workers Builds](https://developers.cloudflare.com/workers/ci-cd/builds/),
  [changelog 2026-10-12](https://developers.cloudflare.com/changelog/post/2026-10-12-faster-pull-request-comments/)).
- **GitHub Actions** — Cloudflare's own example uses `cloudflare/wrangler-action@v4`; latest is
  `v4.1.3` (2026-09-24), commit `953926a2e2182532811c01a25e53647d93bf07c0`. Pin the SHA, per
  `13-dependency-security.md` §13.7
  ([GitHub Actions](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/);
  SHA via `gh api repos/cloudflare/wrangler-action/commits/v4.1.3 --jq .sha`).
- **Worker Previews** — `npx wrangler preview` creates or updates an isolated Preview of the
  current branch under the same Worker, with its own settings from a `previews` block; needs
  Wrangler ≥ 4.135.0. Preview URLs are public by default; the `workers.dev` Preview URL carries
  `X-Robots-Tag: noindex`, and for custom-domain Previews the docs point to Cloudflare Access instead
  ([Previews](https://developers.cloudflare.com/workers/previews/), page last updated 2026-09-24).
  Not the same thing as the `preview_urls` key above, which toggles Version/Preview URLs on
  `workers.dev`.
- **`cf` CLI (beta)** — one CLI for the whole Cloudflare API plus Workers projects, with a typed
  `cloudflare.config.ts` and `cf migrate` to convert a Wrangler config. Cloudflare says commands,
  configuration and build output "can change before the stable release"; do not migrate a site to
  it yet ([changelog 2026-09-28](https://developers.cloudflare.com/changelog/post/2026-09-28-cloudflare-cli-beta/)).

## Zone-level settings (CF dashboard — OAuth token is read-only on zones)

Give the user this checklist for `dash.cloudflare.com → DOMAIN`:

| Path | Setting | Value | Why |
|---|---|---|---|
| SSL/TLS → Overview | Encryption mode | **Automatic** if offered, else **Full (strict)** | Only matters if the zone also proxies to a real origin — see below |
| SSL/TLS → Edge Certificates | Always Use HTTPS | **On** | HTTP→HTTPS redirect; status code undocumented, assert it with `curl` |
| SSL/TLS → Edge Certificates | Automatic HTTPS Rewrites | **On** | Mixed-content protection |
| Security → Settings → Bot traffic | Bot Fight Mode | **Off** | See below |
| Security → Settings → Bot traffic | Configure AI bot policies | A deliberate choice per policy | See "AI crawlers" below |
| Rules → Redirect Rules | www → apex | 301, preserve path/query | The documented www redirect method |
| Caching → Configuration | Invalidate Cache / Purge Cache | (only if you set long `max-age` yourself) | Defaults already revalidate |

Encryption mode. The mode governs the Cloudflare → origin connection, and for a Custom Domain "the
Worker is the origin" — there is no separate origin leg for a Worker-only site, so the mode does
not protect anything there (verified 2026-10-14 —
[Custom Domains](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/)).
Set it correctly anyway, because it applies zone-wide and a hostname added later may proxy to a
real server. Cloudflare labels **Automatic SSL/TLS** the default and is "gradually rolling" it out:
it probes the origin, only ever upgrades (never drops below the current mode), and a zone not yet
migrated shows only the custom modes — pick Full (strict) there
(verified 2026-10-14 — [Encryption modes](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/), page last updated 2026-04-16).

Always Use HTTPS "redirects all your visitor requests from `http` to `https`, for all subdomains
and hosts", is on every plan, and is hidden when the mode is Off; the page does **not** state the
status code it returns (verified 2026-10-14 —
[Always Use HTTPS](https://developers.cloudflare.com/ssl/edge-certificates/additional-options/always-use-https/)).
Read the code from the `http://` probe in the verification block rather than asserting one.

Invalidate vs purge. Since 2026-09-28 the dashboard has **Invalidate Cache** next to purge: it marks
content stale and revalidates with the origin, reusing the cached copy on `304 Not Modified`, which
needs an `ETag` or `Last-Modified` (static assets send `ETag`). Purge removes it outright
(verified 2026-10-14 — [changelog 2026-09-28](https://developers.cloudflare.com/changelog/post/2026-09-28-cache-invalidation/)).
Either only matters at Cloudflare's edge for paths you gave a long `max-age`; neither reaches a
browser cache.

Bot Fight Mode, with sources (verified 2026-10-14 — [Bot Fight Mode](https://developers.cloudflare.com/bots/get-started/bot-fight-mode/), page last updated 2026-08-03):
- It "cannot be customized, adjusted, or reconfigured via WAF custom rules" and cannot be skipped —
  Skip/Bypass/Allow actions have no effect on it.
- It **auto-enables JavaScript Detections, which cannot be disabled**, and that injected script
  fights a strict CSP: you must allow `/cdn-cgi/challenge-platform/` and use CSP nonces, or accept
  `unsafe-inline`.
- It issues CPU-intensive challenges to traffic "matching patterns of known bots" and "may challenge
  API or mobile app traffic".

⚠️ The older claim that Bot Fight Mode "blocks legitimate AI crawlers" is not something Cloudflare's
docs state — removed rather than repeated. The CSP conflict above is the sourced reason to leave it
off for a static marketing site. AI-crawler policy is a separate feature, below.

### AI crawlers — AI bot policies, not "Block AI bots"

The single **Block AI bots** toggle is headed "Deprecating on September 15, 2026". Its replacement
is **Configure AI bot policies** under Security Settings: three policies — **Search** (indexing to
answer later), **Agent** (real-time fetches on a person's behalf) and **Training** (including
mixed-purpose Search+Training crawlers) — each set to Block on all pages, Block on pages with ads,
or Allow (verified 2026-10-14 —
[Block AI Bots](https://developers.cloudflare.com/bots/additional-configurations/block-ai-bots/), page last updated 2026-07-01).

The same page says that on 2026-09-15 Cloudflare "will set updated defaults for new domains":
Training and Agent blocked on pages that display ads, Search allowed. ⚠️ That is Cloudflare's page
written ahead of the date; no primary source read on 2026-10-14 confirms the switch happened. On a
zone added after that date, open the policies page and read what is actually set before assuming
either way.

The managed robots.txt is now driven by these policies through **Bot Preference Sync**
(verified 2026-10-14 — [robots.txt setting](https://developers.cloudflare.com/bots/additional-configurations/managed-robots-txt/), page last updated 2026-10-08):
- Directives are generated once a policy is set to Block, Block on pages with ads, or (Training)
  Disallow, with **Enable Bot Preference Sync** turned on. Cloudflare prepends its block to an
  existing `robots.txt` that answers 200, or serves its own if there is none.
- The managed content carries `Content-signal: search=yes, ai-train=no, use=reference` — `use` is a
  fourth field Cloudflare is testing (`immediate` / `reference` / `full`).
- **Free-plan zones with no `robots.txt` of their own** and no managed robots.txt get Cloudflare's
  Content Signals Policy text served at `/robots.txt` — so a site that "has no robots.txt" may
  still answer one. Ship your own file to control it.
- Google Search Console "may occasionally report `Syntax not understood`" for these lines;
  Cloudflare says it has seen no crawling or SEO impact. Do not chase that warning as a bug.

What the signals do and do not achieve is covered in `06-agent-ready.md`.

## Gotchas

- **A Worker script does not run for requests that match a static asset.** The single most expensive
  mistake in this file's history: host redirects and header logic written in a Worker appear to work
  (random paths 301 correctly) while every real page bypasses them. Set `run_worker_first`, or move
  the logic to a zone rule. (verified 2026-10-14 — [Routing / Worker script](https://developers.cloudflare.com/workers/static-assets/routing/worker-script/))
- **`workers_dev` flips to `false` when you add `routes`** — "If you do not specify
  `workers_dev = false` but add a routes component … the value of `workers_dev` will be inferred as
  `false` on the next deploy." Set `"workers_dev": true` explicitly to keep both. Version and
  Preview URLs are a separate switch, `preview_urls`: turning `workers.dev` off does not turn them
  off, and they only take their initial value from `workers_dev` when no setting exists yet.
  (verified 2026-10-14 — [workers.dev](https://developers.cloudflare.com/workers/configuration/routing/workers-dev/),
  [Wrangler configuration](https://developers.cloudflare.com/workers/wrangler/configuration/))
- **`_headers` and `_redirects` do not apply to Worker-generated responses**, even when the request
  URL matches a rule. Any site with a Worker script must verify its security headers on a live URL.
  (verified 2026-10-14 — headers/redirects pages above)
- **`_redirects` with `/*  /  302` matches `/` itself.** The docs document no loop protection; they
  only guarantee that the top-most matching rule wins and that "redirects are always followed". Use
  `not_found_handling: "single-page-application"` for SPA fallback rather than a catch-all redirect.
  (verified 2026-10-14 — [Redirects](https://developers.cloudflare.com/workers/static-assets/redirects/))
- **OAuth token carries `zone:read` only.** `npx wrangler@4.151.0 login --scopes-list` (run
  2026-10-14; it lists scopes without logging in) shows exactly one zone scope, `zone:read`. So the
  CLI cannot create redirect rules, change SSL mode, or purge/invalidate cache — every zone-level
  operation is user-via-dashboard. Optional scopes only let you grant *fewer*. Confirm with that
  command rather than trusting this line.
- **Finder drag-upload hides dotfiles** — `.well-known/` disappears silently. ⚠️ macOS behaviour,
  not a Cloudflare claim, and not verifiable from a vendor doc; treated as an operational habit:
  always deploy via `wrangler deploy`.
- **Removed: "stale 200s survive redeploy, purge everything before retesting."** Static assets are
  served with `Cache-Control: public, max-age=0, must-revalidate` plus an `ETag` by default, which
  the docs say guarantees "stale content will never be served" (re-read 2026-10-14). Purging or
  invalidating is only relevant for paths where *you* set a long `max-age`/`immutable` in
  `_headers` — and browser-side, neither reaches those. Test with a cache-busting query string
  instead.
- **Removed: "dashboard Upload and deploy leaves Bindings=0."** ⚠️ This was an undated field
  observation with no vendor documentation behind it, and the dashboard upload flow has changed
  since. The CLI-first advice stands on its own merits (reproducible, dotfile-safe, config in git) —
  do not attribute it to a bug that cannot be shown to exist today.

## Verification after deploy

```bash
# Resolve through Cloudflare's current anycast IPs rather than a hardcoded address. `dig +short`
# can print a CNAME before the address; keep the first IPv4 line only.
IP=$(dig +short DOMAIN | grep -E '^[0-9.]+$' | head -1)
[ -n "$IP" ] || echo "?    DOMAIN did not resolve — the probes below cannot run"

for p in / /favicon.svg /robots.txt /sitemap.xml /.well-known/security.txt /og-cover.png; do
  printf '%s -> ' "$p"
  curl -sI --resolve DOMAIN:443:$IP "https://DOMAIN$p" | head -1
done

# Security headers actually present on a real page (not just on a 404 miss)
curl -sI --resolve DOMAIN:443:$IP "https://DOMAIN/" | grep -iE 'strict-transport|content-security|x-frame|referrer-policy'

# www -> apex, tested on BOTH a real page and a random path
curl -sI --resolve www.DOMAIN:443:$IP "https://www.DOMAIN/" | head -3
curl -sI --resolve www.DOMAIN:443:$IP "https://www.DOMAIN/test-$(date +%s)" | head -3
# Expect 301 + Location: https://DOMAIN/... on BOTH. If only the random path redirects,
# the Worker is running behind asset serving — see the routing-order section.

# The http:// legs. Always Use HTTPS does not document its status code, so print what it is.
for h in DOMAIN www.DOMAIN; do
  printf 'http://%s/ -> ' "$h"
  curl -sI --resolve $h:80:$IP "http://$h/" | grep -iE '^(HTTP|location)' | tr -d '\r' | paste -sd' ' -
done
# Expect a 3xx to https:// on both. http://www.DOMAIN/ landing on https://www.DOMAIN/ (not the
# apex) is the two-hop case from the www section — fine, or widen the rule to http*://www.*.
# Full chain in one line:
curl -sIL -o /dev/null -w '%{num_redirects} hops -> %{url_effective}\n' "http://www.DOMAIN/"
```

All 200, www 301 on both the real page and the random path, and both `http://` probes redirecting
to `https://`. A random path on the apex is
`404` when `not_found_handling` is `"404-page"` (multi-page site) and `200` only on a real
client-routed SPA — decide which from the field notes above before reading the result. See
`11-validation-toolkit.md` for the full probe suite.
