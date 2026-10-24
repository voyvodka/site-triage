# Changelog

All notable changes to the `site-triage` plugin (named `web-launcher` before 1.0.0) are
documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Content carries verification dates; a release that only re-verifies claims still gets an entry.

## [Unreleased]

### Changed

- The skill now also triggers on the Turkish Search Console labels, such as "Tarandı: Şu anda dizine eklenmiş değil" and "Yönlendirmeli sayfa" (#18)

## [1.1.0] - 2026-10-24

### Added

- Diagnostic check C11 reads a Cloudflare zone's AI Training policy and fails when it also blocks Googlebot, Bingbot and Applebot (#14)
- Eval suite for `claude plugin eval`: triggering in English and Turkish, the three core rules, brand-only scope, and a mocked GeoDaddy run (#15)

### Fixed

- Dependabot advice now covers npm 12 and pnpm 11–12, and warns that two-document pnpm 12 lockfiles get no security alerts (#13)
- Corrected the CodeQL action pin, Socket's free-plan seats, Bing's submission-quota quote and the ChatGPT URL; removed an unsourced `rel="me"` claim (#13)
- Cloudflare AI bot advice now says Training = Block also blocks Googlebot and recommends Disallow AI Training instead (#14)

## [1.0.0] - 2026-10-14

### Changed

- **`web-launcher` is renamed to `site-triage`.** BREAKING: install with
  `/plugin install site-triage@voyvodka` and run `/site-triage`. Claude Code 2.1.193+ rewrites
  `enabledPlugins` automatically; expect one `plugin-cache-miss` and a reinstall. No content changed.

## [0.4.0] - 2026-10-14

### Added

- **AI-search visibility reports.** Bing Webmaster Tools' AI Performance and Search Console's
  Generative AI performance report are covered, with a first check for zero AI impressions (`04`,
  `15`, `16`).
- Release-age gates for npm, pnpm, Bun and Yarn, and npm 12's blocking of dependency install
  scripts unless `allowScripts` allows them (`13`).
- Cloudflare's AI bot policies (Search, Agent, Training), Bot Preference Sync and the managed
  robots.txt `use=reference` line (`06`, `08`, C2 in `14`).
- User-triggered fetchers such as ChatGPT-User are no longer listed as robots.txt controls;
  Meta-WebIndexer, Amzn-SearchBot and OAI-AdsBot are added (`03`, `15`).
- The live probes in `08`, `09` and `11` print a verdict for every check, including
  `000`/`NO RESPONSE` and `MISSING:` lines.
- `08` covers Workers Builds, `wrangler-action` v4, Worker Previews, the `cf` CLI beta, cache
  Invalidate, redirect status codes per mechanism, and an `http://` probe.

### Changed

- **Content re-verified on 2026-10-14; review due 2026-12-13.** Claims that could not be re-read
  keep their older stamp or a ⚠️.
- Search Console's reason table (`16`) uses Google's current labels and adds the missing reasons,
  including Redirect error, Server error (5xx), 401, 403, Duplicate without user-selected canonical,
  Discovered – currently not indexed, and the warnings "Indexed, though blocked by robots.txt" and
  "Page indexed without content".
- Google's published timings for crawling after a request and for duplicate clusters replace
  "Google publishes no timing".
- `07` covers satori 0.56.1's breaking layout changes: `@vercel/og` 1.0.3 still runs satori
  0.33.5, direct satori does not.
- `06` covers isitagentready's 22 checks and API, and scopes the plugin to four of its signals.
- GitHub Actions guidance pins every action by SHA and covers the workflow lockfile; the `13`
  §13.11 pin check reads more ref formats and ends in an OK/FAIL line.
- Dependabot's default 3-day cooldown and per-ecosystem limits are documented, and that pnpm 12 and
  npm 12 fall outside its documented versions (`13`).
- Versions re-resolved on 2026-10-14: wrangler `4.151.0`, satori `0.56.1`, svelte-sitemap
  `4.1.2`, `setup-node` v7.1.0, `codeql-action` v4.38.3, `pnpm/setup` v3.1.1, pnpm `12.11.2`,
  TruffleHog `v3.99.2`, Syft `v1.54.1`.
- `08` and `13` match current vendor docs on Pages versus Workers, `--use-keyring`, Automatic
  SSL/TLS, Secret Protection, Node 20 runners and npm trusted publishing.
- README leads with the one-step install, `/plugin install web-launcher --marketplace
  voyvodka/claude-plugins` (Claude Code 2.1.275 or later).

### Fixed

- **SVG logos are allowed** for `Organization.logo`; Search favicons still need an ICO (`01`,
  `03`, `10`).
- `12` and `16` list the Search Console API's other writes (`sitemaps.delete`, `sites.add`,
  `sites.delete`), which the plugin never calls.
- Web Bot Auth uses the correct directory media type and a signed response; the advice to publish
  an empty key set is withdrawn (`06`, `09`, `13`, `SKILL.md`).
- The baseline `Permissions-Policy` no longer ships the deprecated `browsing-topics=()` (`08`).
- The Markdown-for-Agents middleware no longer sets the dropped `X-Markdown-Tokens` header and adds
  `Vary: Accept` (`06`).
- `llms.txt` is linked with `rel="describedby"`, not `alternate` (`03`, `06`, `08`).
- A single trailing-slash redirect reports as "Page with redirect", not "Redirect error", and
  Googlebot follows up to ten hops (`09`, `14`, `SKILL.md`).
- The SoftwareApplication template is marked ineligible for the rich result without
  `aggregateRating` or `review`, which must never be invented (`03`, `09`).
- `security.txt` `Expires` is under a year, per RFC 9116, and the sitemap template drops
  `<changefreq>` and `<priority>` (`03`).
- 302/307 are a weak canonical signal, not none (`14`); `sizes` on `<link rel=icon>` is optional
  (`01`); theme-color applies only to installed web apps in desktop Chrome and Safari 26 (`01`,
  `02`, `03`).

## [0.3.3] - 2026-09-25

### Added

- README: what to do when GeoDaddy fails to connect, including `MCP_TIMEOUT` for the slow first
  `npx` start and a failed analyzer download that breaks only `analyze_url`.

### Changed

- Versions re-resolved on 2026-09-25: satori `0.33.5`, `@vercel/og` `1.0.3`, `astro-og-canvas`
  `0.13.2`, `@astrojs/sitemap` `3.7.4`, wrangler `4.140.0`, Lighthouse `13.5.0`, `codeql-action`
  `v4.38.2`, TruffleHog `v3.97.9`, Syft `v1.52.0`, CycloneDX spec `1.7.2`.
- **pnpm 12 in `13-dependency-security.md`.** The example pins the `pnpm/action-setup` `v6.1.0`
  SHA with `version: 12`, and notes that `pnpm/setup` `v3` installs pnpm 11+ only and runs
  `pnpm install` by default.
- `11` lists all seven Lighthouse 13.5.0 Agentic Browsing audits, including the new `ard-schema`
  (`ai-catalog.json`) audit.
- `06` names AIPREF's provisional `ai-use` category (`draft-ietf-aipref-vocab-08`) as the
  counterpart to `Content-Signal`'s `ai-input`.

### Removed

- Every unsourced indexing and logo timeline in `10` and `12`; they now say "days to weeks,
  depending on crawl frequency" and point to Search Console.

### Fixed

- **C1 passes a correct `404`.** A redirect ending anywhere but `200` fails, a `5xx` fails, and the
  OK line counts how many probes redirected.
- **C3 requires consolidation:** exactly one variant may answer `200`; the others must 301/308 into
  it.
- `09`'s action-pin check now runs `13.11` check 4.
- The baseline CSP no longer carries `script-src 'unsafe-inline'`.
- **`SKILL.md`'s always-loaded pitfalls match `08`**: no unconditional SPA fallback, no unsourced
  field observations, and a zone rule instead of a Worker redirect.
- `08`'s Worker-redirect variant no longer hardcodes the SPA fallback or expects random paths to
  answer `200`, and `11.1` no longer tests www→apex only on a random path.
- `09` and `11` take the probe address from DNS instead of a hardcoded Cloudflare IP.
- **`15`'s citation check resolves each token to its governing robots.txt group** and now sees a
  `Disallow` under `User-agent: *`; GeoDaddy's training-crawler count is corrected to five.
- `16` maps "Blocked by robots.txt" to `robotsTxtState` and `pageFetchState` instead of the
  retired `indexingState: BLOCKED_BY_ROBOTS_TXT`.
- `13.11` no longer runs `yarn outdated` on Yarn Berry, and the `13.3` workflow SHA-pins its
  third-party actions.
- `06` no longer calls `sitemap` and `security-txt` IANA-registered or recommends the empty JWKS
  placeholder, and points to `14` C2 for the live-vs-repo diff.
- `Content-Signal` and the empty JWKS placeholder are intent-only everywhere, no longer proposed
  as fixes or rated 🟡 (`09`, `13.11`).
- `mask-icon` is gone everywhere, and `02` and `03` include the `favicon.ico` that `01` requires.
- `02` no longer states as verified two iOS claims that lack a primary source.
- `05`'s orphan check no longer reports every page as an orphan.
- `11` drops retired Lighthouse font-size and tap-target audits and counts the WebMCP audits
  correctly.
- `03`'s humans.txt template and `13`'s examples no longer carry a real project's stack or a real
  timezone.
- `01`'s emoji search no longer uses `grep -P`, so it works with macOS grep.
- `14`: C2 prints a result on success, C5 handles a sitemap index, and C6/C9 match tags whose
  attributes come in either order.
- `03`'s `llms.txt` claim cites Google's documentation update and marks the crawler-traffic claim
  as secondary.
- `SKILL.md` no longer runs the Mode-B-only live probe in Mode A, counts 15 validators, and leads
  its description with the trigger keywords.

## [0.3.2] - 2026-09-08

### Fixed

- The 0.3.0 and 0.3.1 entries in this changelog no longer list the same fixes twice under two
  `### Fixed` headings.

## [0.3.1] - 2026-08-28

### Fixed

- **C4 and C7 no longer pass an unreachable origin**: both detect the `000` sentinel first and
  print `?  not checked`.
- **`13-dependency-security.md` runs one audit tool**: the Mode B sweep picks the package manager
  from the lockfile, with `bun` and `yarn` branches, instead of `pnpm audit || npm audit`.
- The `@vercel/og` row in `07-og-satori.md` says `1.0.2` (published 2026-08-24, pinning
  `satori@0.33.3`), matching the prose.
- The claim that Workers has no "deployment finished" event is marked partly verified; the advice
  to add a step after `wrangler deploy` is unchanged.

## [0.3.0] - 2026-08-28

### Changed

- `16-search-console.md` defaults to the `webmasters.readonly` scope, widening only when the user
  asks and confirms the sitemap URL, and states it is a procedure, not client code.
- `14-diagnostic-checks.md` warns that C5, C7 and C9 request URLs taken from the audited site's
  content.

### Fixed

- **Diagnostic checks no longer report a skipped or failed run as healthy** (`14`): C1 passes only
  a final `200` and flags a host that never answered, C5 and C7 flag zero URLs read, and C9 prints a
  counted OK line.
- **The baseline `wrangler.jsonc` no longer ships an SPA fallback to every site**;
  `not_found_handling: "single-page-application"` now depends on the site shape.
- `03`'s meta template uses raster images for `apple-touch-icon` and `Organization.logo`, matching
  `01` and `10`.
- **The checks run in a POSIX shell**: every block in `14`, `09` and `11` passes `dash -n` as well
  as `bash -n`.
- **Audits run exactly one scanner**: `pnpm audit … || npm audit …` is replaced with
  `packageManager`-then-lockfile detection, `bun` included.
- `09-audit-workflow.md` no longer says "Commit logically"; commit, push, deploy, cache purge,
  sitemap submit and DNS changes each need their own named approval.
- **`15-geo-measurement.md` classifies `ClaudeBot` as a training crawler**, explains the
  `GoogleOther` check GeoDaddy runs, and adds a `curl` check against the tokens that decide
  citation.
- `10-brand-serp.md`'s canned user message no longer reports "Requested indexing via GSC" as done.
- `SKILL.md`'s Mode C stops at step 3 instead of running a full-scope scan.
- `08-cloudflare-deploy.md` no longer justifies CSP `'unsafe-inline'` by inline JSON-LD.
- `01-brand-application.md` matches the icons its `site.webmanifest` references, and its
  verification checklist uses per-category placeholder searches.
- **`og:url` is set per route**: `03`'s meta template no longer hardcodes the site root, `05` lists
  it among per-route overrides, and `03` says when to load `05`.
- `06-agent-ready.md`'s section header no longer says to "ship the top two always".
- `02-coming-soon-scaffold.md`'s skeleton loads all three font families its typography section
  specifies.
- `11-validation-toolkit.md` requests reindexing once per URL per content change, not on every
  meaningful change.
- `12-indexing.md` describes IndexNow automation as a deploy-pipeline step, not a "wrangler deploy
  event".
- `13-dependency-security.md` says how to choose when a repo runs both Dependabot and Renovate, and
  that deleting the config alone does not stop Renovate.

## [0.2.0] - 2026-08-28

### Changed

- `.mcp.json` pins `geodaddy-mcp@0.2.2` instead of running the registry's `latest`.
- Version claims refreshed on 2026-08-28: satori `0.29.0` → `0.33.4`, `codeql-action` →
  `v4.37.9`, TruffleHog → `v3.97.1`, Syft → `v1.51.1`, pnpm → `11.24.0`; satori's CSS-support
  claims are marked not re-verified.

### Fixed

- **Two action pins in `13-dependency-security.md` resolve**: `github/codeql-action` v4 and
  `pnpm/action-setup` v6 point at real commits, and the file gives a one-step resolution command.
- **`06-agent-ready.md` reports AIPREF status correctly**: `draft-ietf-aipref-attach` is live as
  `-05` until 2027-02-20, `vocab` is at `-07`, and `Content-Usage` stays intent-only.
- `$schema` added to `plugin.json`, pointing at the SchemaStore entry.

[Unreleased]: https://github.com/voyvodka/site-triage/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/voyvodka/site-triage/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/voyvodka/site-triage/compare/v0.4.0...v1.0.0
[0.4.0]: https://github.com/voyvodka/site-triage/compare/v0.3.3...v0.4.0
[0.3.3]: https://github.com/voyvodka/site-triage/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/voyvodka/site-triage/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/voyvodka/site-triage/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/voyvodka/site-triage/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/voyvodka/site-triage/releases/tag/v0.2.0
