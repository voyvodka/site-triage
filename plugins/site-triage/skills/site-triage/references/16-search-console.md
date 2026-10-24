# Search Console — reading index status without guessing

*Loaded by `site-triage` SKILL whenever a live site's indexing is in question, or the user
mentions Search Console, "not indexed", "not appearing in Google", or a coverage reason.*

> **Verified 2026-10-14 · review by 2026-12-13.** Endpoint surface, field names, enum values and
> quotas were read from Google's API reference. Claims marked ⚠️ could not be confirmed against a
> primary source and say why.
>
> **This file is a procedure, not shipped code.** There is no OAuth handler, no token store and no
> API client in this plugin, and there is not meant to be. It documents the endpoint surface and the
> one-time setup so the agent reading it can drive the API with whatever HTTP client the session
> already has. If you were looking for an integration to run, this is not one — and nothing else in
> the plugin depends on there being one.

## The four walls — read these before promising anything

**1. The "why pages aren't indexed" report cannot be downloaded.** The whole API is four resources:
`sites`, `sitemaps`, `searchanalytics`, `urlInspection`. There is **no coverage endpoint**, and the
BigQuery bulk export contains only performance tables — no indexing-status table (verified
2026-10-14 — [API reference](https://developers.google.com/webmaster-tools/v1/api_reference_index),
[bulk export table reference](https://support.google.com/webmasters/answer/12917991)). The URL list
behind "Page with redirect ×37" is not obtainable programmatically.

→ So the report is **reconstructed, not fetched**: build a candidate URL set yourself, then inspect
each URL. Your numbers will not match the interface exactly, and you must say so — Google knows
URLs your sitemap and crawl do not contain.

**2. Nothing can be requested, validated, or resubmitted.** "Request indexing" and "Validate fix"
exist only in the interface. The Indexing API covers only `JobPosting` and `BroadcastEvent` (in a
`VideoObject`), not general web pages. The only write that tells Google anything about the site's
content is `sitemaps.submit`. The API's other writes — `sitemaps.delete`, `sites.add`,
`sites.delete` — change the Search Console account, not what Google knows, and this plugin never
calls them (verified 2026-10-14 —
[API reference](https://developers.google.com/webmaster-tools/v1/api_reference_index),
[Indexing API quickstart](https://developers.google.com/search/apis/indexing-api/v3/quickstart)).

→ Never say "I've told Google to recrawl". Say what you changed, submit the sitemap, and hand the
user the interface link for the rest.

**3. URL Inspection returns the *indexed* version, not the live one.** There is no live-test method
in the API. Right after a fix, it still reports the old state.

→ The honest sentence is: *"live HTTP is now correct; Google has not recrawled yet."* Prove the
first half with `14-diagnostic-checks.md`, and let the second half take its time.

**4. "Crawled – currently not indexed" is not a technical defect.** Google's definition gives no
reason, and their guidance is repeatedly that it is a quality/redundancy judgement rather than a
bug. ⚠️ (guidance is from talks and office hours; not in written documentation)

→ Do not claim you can close it. Name it, say it is a content/authority question, move on.

## Auth — OAuth 2.0, and nothing else

*"Your application must use OAuth 2.0 to authorize requests. No other authorization protocols are
supported."* Scopes: `.../auth/webmasters` (read-write, needed for `sitemaps.submit`) and
`.../auth/webmasters.readonly`.

**Default to `webmasters.readonly`.** Everything this file is loaded for — reading index status,
reconstructing the candidate set, mapping a coverage reason to its cause — is a read. The
read-write scope buys one operation this plugin uses, `sitemaps.submit` (plus `sitemaps.delete`,
`sites.add` and `sites.delete`, which it never calls), and a token that can submit is a token that
can submit by accident: a sitemap URL is a production input to how Google crawls the
site, and the mistake is not visible until it is indexed. Ask for the wider scope only when the
user has asked for a sitemap submission specifically, and **confirm the exact sitemap URL with them
immediately before the call** — approval of "audit my site" is not approval to write to it. Say
which scope you are using when you set the integration up.

**A domain property is named `sc-domain:example.com`** in the API, not as a URL. URL-prefix
properties are named by their URL with the trailing slash. `sites.list` returns the exact strings —
read them from there rather than constructing them, and pass one as `siteUrl` on every inspect call.

**Use a desktop OAuth client.** One-time setup, then a refresh token stored locally:

1. Google Cloud console → new project (or reuse one).
2. Enable **Google Search Console API**.
3. OAuth consent screen → External → **Publish it.** Left in "Testing", refresh tokens expire after
   seven days and the integration silently dies a week later (verified 2026-10-14 —
   [Using OAuth 2.0 to Access Google APIs](https://developers.google.com/identity/protocols/oauth2),
   "Refresh token expiration").
4. Credentials → Create OAuth client ID → **Desktop app** → download the JSON.
5. Run the authorization flow once, store the refresh token outside the repository.

Two alternatives, both rejected as the default: a **service account** works — it must be added as a
user on *each* property, and forgetting one returns 403 — but it puts a key file on disk and Google
does not document it as the primary path. **ADC** (`gcloud auth application-default login`) is
undocumented for this API and requires the gcloud SDK, which is a heavier install than one browser
round.

**Dependencies:** the API surface is tiny and the hard part is token refresh, not fetching. An auth
library plus plain `fetch` gives more control than a full client library for far less weight.

## Reconstructing the candidate set

Since the URL list cannot be fetched, build it — and be explicit that each source has a blind spot:

| Source | Catches | Misses |
|---|---|---|
| `sitemap.xml` (follow the index) | Everything the site declares canonical | Every variant Google discovered elsewhere |
| Internal-link crawl | Pages reachable from the site | Orphans and historical URLs |
| **Generated variants** of each canonical URL: trailing-slash flipped, `www`/apex swapped, `http`, `index.html` appended, uppercase | The redirecting twins that dominate "Page with redirect" | Variants you did not think to generate |
| Framework redirect map and `_redirects` | Legacy aliases | — |
| Old sitemaps and previous deploy artefacts | Historical URLs | — |

The variants row is the one that matters. In a healthy site, canonical URLs plus their generated
twins account for nearly all of what Google knows — and that arithmetic is what lets you say a
number is *expected* rather than *broken*.

## Branching — on enums, never on prose

`urlInspection.index.inspect` returns `indexStatusResult`. Use these:

```
verdict          PASS | FAIL | NEUTRAL | VERDICT_UNSPECIFIED
robotsTxtState   ALLOWED | DISALLOWED | ROBOTS_TXT_STATE_UNSPECIFIED
indexingState    INDEXING_ALLOWED | BLOCKED_BY_META_TAG | BLOCKED_BY_HTTP_HEADER
                 | INDEXING_STATE_UNSPECIFIED
pageFetchState   SUCCESSFUL | SOFT_404 | BLOCKED_ROBOTS_TXT | NOT_FOUND | ACCESS_DENIED
                 | SERVER_ERROR | REDIRECT_ERROR | ACCESS_FORBIDDEN | BLOCKED_4XX
                 | INTERNAL_CRAWL_ERROR | INVALID_URL | PAGE_FETCH_STATE_UNSPECIFIED
googleCanonical  string — the canonical Google picked
userCanonical    string — the canonical you declared
lastCrawlTime, crawledAs, sitemap[], referringUrls[], inspectionResultLink
```

Two values Google still lists are marked *"Reserved, no longer in use"*: `verdict PARTIAL` and
`indexingState BLOCKED_BY_ROBOTS_TXT` (verified 2026-10-14; the enum block above re-read the same day —
[UrlInspectionResult reference](https://developers.google.com/webmaster-tools/v1/urlInspection.index/UrlInspectionResult)).
Never branch on either; a robots.txt block surfaces as `robotsTxtState: DISALLOWED` and
`pageFetchState: BLOCKED_ROBOTS_TXT`.

**`coverageState` is a free-text string, not an enum.** Google types it as `string` and publishes no
list of values — and **it is translated according to `languageCode`**. Branch on it and the logic
breaks silently on a non-English account, which is the worst kind of failure: it does not error, it
just decides wrongly.

- **Pin `languageCode: "en-US"` on every request.**
- Branch on `pageFetchState` + `indexingState` + `googleCanonical != inspectionUrl`. Those are real
  enums and language-independent.
- Quote `coverageState` in reports for the human. Never test against it.

`sitemap[]` and `referringUrls[]` may come back empty, and empty means *not available*, not *none*.
Do not conclude "no page links here" from an empty `referringUrls` — crawl for that instead.

## From reason to cause

Labels are Google's current ones, in English — quote them that way and match the user's pasted
report against them loosely, since the interface is localized (verified 2026-10-14 —
[Page indexing report](https://support.google.com/webmasters/answer/7440203),
[UrlInspectionResult reference](https://developers.google.com/webmaster-tools/v1/urlInspection.index/UrlInspectionResult)).
The Turkish column is the same report in Turkish, where the "Not indexed" group is headed
*Dizine eklenmedi* — match a Turkish paste against it, still loosely (verified 2026-10-25 —
[Sayfa dizine ekleme raporu](https://support.google.com/webmasters/answer/7440203?hl=tr)).

| What Google reports | Turkish label | Read it as | Where the cause lives |
|---|---|---|---|
| Page with redirect | Yönlendirmeli sayfa | `verdict: NEUTRAL`, `googleCanonical != inspectionUrl`, fetch redirects | Usually **expected** — the redirecting twin of a canonical URL. A single valid `301`/`308` lands here, never under *Redirect error* — one redirect to a bad, empty or over-long URL is a *Redirect error*. A defect only when the target is not 200 (`14-diagnostic-checks.md` C1), the redirect is temporary (C3), or it takes more than one hop (C4) |
| Redirect error | Yönlendirme hatası | `pageFetchState: REDIRECT_ERROR` | Google lists four causes: a chain that was too long, a loop, a redirect URL that exceeded the maximum URL length, a bad or empty URL in the chain. Measure the chain with C4 and where it ends with C1 |
| Not found (404) | Bulunamadı (404) | `pageFetchState: NOT_FOUND` | A redirect issued before the target was resolved (C1), a sitemap listing dead URLs (C5), or an old external link. Trace it; do not delete the URL and call it fixed |
| Soft 404 | Soft 404 | `pageFetchState: SOFT_404` | A thin or empty page returning 200 (C7) |
| Server error (5xx) | Sunucu hatası (5xx) | `pageFetchState: SERVER_ERROR` | The origin, or an edge rule in front of it, failing for Googlebot. C1 prints a 5xx on a probe path; then read server logs and any CDN/WAF rule |
| Blocked due to unauthorized request (401) | Yetkisiz istek (401) nedeniyle engellendi | `pageFetchState: ACCESS_DENIED` | An auth gate on a public URL — staging protection left on, usually |
| Blocked due to access forbidden (403) | Erişim izni verilmemesi (403) nedeniyle engellendi | `pageFetchState: ACCESS_FORBIDDEN` | Googlebot never sends credentials, so Google calls a 403 to it an error on the server's side. Usually a bot-blocking rule at the CDN or WAF. On Cloudflare, check first an AI bot policy with Training = Block or Block on pages with ads, which also blocks Googlebot since 2026-09-15 — `14` C11 (⚠️ the status code it returns is undocumented; putting it first generalises one zone observed on 2026-10-24, it is not a measured frequency) |
| URL blocked due to other 4xx issue | URL başka bir 4xx sorunu nedeniyle engellendi | `pageFetchState: BLOCKED_4XX` | Any 4xx other than 401, 403, 404. Read the actual status with `curl -sI` and the URL Inspection tool |
| URL blocked by robots.txt | URL, robots.txt tarafından engellendi | `robotsTxtState: DISALLOWED` / `pageFetchState: BLOCKED_ROBOTS_TXT` | Check the **live** file, not the repository — a CDN may be injecting rules (C2) |
| URL marked 'noindex' | URL "noindex" olarak işaretlenmiş | `BLOCKED_BY_META_TAG` / `BLOCKED_BY_HTTP_HEADER` | Staging leftovers, or a shell served without the render path (C7) |
| Alternate page with proper canonical tag | Doğru standart etikete sahip alternatif sayfa | `googleCanonical` points elsewhere and you agree | Normal. Only a problem if you did *not* intend that canonical (C6) |
| Duplicate without user-selected canonical | Kullanıcı tarafından seçilen standart sayfa olmadan kopya | `googleCanonical` set, `userCanonical` absent | The page declares no canonical and Google picked one. Google calls this working as intended; declare a canonical only if its pick is wrong (C6) |
| Duplicate, Google chose different canonical than user | Kopya, Google kullanıcıdan farklı bir standart sayfa seçti | `googleCanonical != userCanonical` | Real conflict — your declared canonical is being overruled. Check for duplicate content and mismatched signals (C6, C7). After a fix, Google may hold pages in the duplicate cluster for up to two weeks (verified 2026-10-14 — [Fix canonicalization issues](https://developers.google.com/search/docs/crawling-indexing/canonicalization-troubleshooting)) |
| Crawled – currently not indexed | Tarandı: Şu anda dizine eklenmiş değil | — | Not technical. Say so |
| Discovered – currently not indexed | Bulundu: Şu anda dizine eklenmiş değil | — | Google rescheduled the crawl because it expected to overload the site; not a technical defect in a file (`12-indexing.md`) |
| Indexed, though blocked by robots.txt *(warning)* | robots.txt tarafından engelleniyor olsa da dizine eklendi | `robotsTxtState: DISALLOWED` on an indexed URL | robots.txt blocks crawling, not indexing — Google indexed the URL from links pointing at it. To keep it out, allow crawling and serve `noindex` |
| Page indexed without content *(warning)* | Sayfa içerik olmadan dizine eklendi | — | Google could not read the content: cloaking, or a format it cannot index. Not a robots.txt block. An empty shell (C7) is the first suspect |

## Deciding "expected" from enums — measured, not inferred

Live `urlInspection` responses from a healthy domain property, 2026-08-14. This is the shape to
branch on:

| URL | `verdict` | `coverageState` (display only) | `googleCanonical` |
|---|---|---|---|
| `https://example.com/docs/` — canonical | **PASS** | "Submitted and indexed" | itself |
| `https://example.com/docs` — slashless twin | **NEUTRAL** | "Page with redirect" | `…/docs/` |
| `https://example.com/old-alias` — never discovered | **NEUTRAL** | "URL is unknown to Google" | absent |

**`verdict` is the signal, and it is an enum.** Google itself does not call the redirecting twin a
failure — it returns `NEUTRAL`, not `FAIL`. So the expected-variant case is decidable without ever
reading translated prose:

```
verdict == NEUTRAL
  and googleCanonical is set
  and googleCanonical != inspectionUrl
  and inspect(googleCanonical).verdict == PASS
      → expected. The variant redirects to a canonical that is indexed. Not a defect.
```

Two more shapes worth naming, both also enum-decidable:

- `verdict == NEUTRAL` with `googleCanonical` **absent** and every state `*_UNSPECIFIED` — Google
  has never discovered the URL. Nothing is wrong with the page; it simply is not in the index and
  is not in any "not indexed" count either. A legacy alias nobody links to lands here.
- `verdict == FAIL` — this is where `pageFetchState` and `indexingState` earn their place:
  `NOT_FOUND`, `SOFT_404`, `BLOCKED_ROBOTS_TXT`, `BLOCKED_BY_META_TAG` each point at a different
  file.

Quote `coverageState` to the human — it is the string they see in the interface — and never test
against it.

## The verdict that is usually right

**Most "not indexed" counts on a healthy site are not defects.** A site with 40 canonical URLs whose
slashless twins all return a permanent redirect will show roughly 39 "Page with redirect" entries —
and every one of them is Google correctly consolidating on the canonical.

So the first output of any Search Console diagnosis is one of two sentences:

- *"This is expected. Here is the arithmetic: N canonical URLs, M generated variants, and the
  variants account for the excluded count."*
- *"This is a defect. Here is the check that failed, the URL, and the file or dashboard setting
  that causes it."*

Say the first one when it is true. Chasing a false positive costs more than not looking, because it
ends in changes to a site that was working.

## Quotas

Per site: URL Inspection **600 QPM / 2,000 QPD**; Search Analytics 1,200 QPM. Every other resource
is limited per user, 20 QPS / 200 QPM. Per project the ceilings are far higher (verified
2026-10-14 — [Usage limits](https://developers.google.com/webmaster-tools/limits)).

The per-site daily cap is the one that binds: a site over ~2,000 URLs cannot be fully inspected in a
day, and several properties in one day accumulate against separate site caps but the same project
cap. Inspect the candidate set in priority order — sitemap URLs first, generated variants second —
and say what was not inspected rather than silently truncating.

## AI Overviews and AI Mode — interface only

**The Generative AI performance report has no API.** Search Console's *Generative AI performance
report* shows a site's impressions in AI Overviews and AI Mode by page, country, device and date;
it rolled out to all sites on 2026-08-31. Its data is part of the Web search type, but neither
`searchanalytics.query` (`type`: `web`, `image`, `video`, `news`, `discover`, `googleNews`) nor the
bulk export's `search_type` has a generative-AI value, so the breakdown cannot be fetched — read it
in the interface or use the report's own export button (verified 2026-10-14 —
[Introducing Search Generative AI performance reports](https://developers.google.com/search/blog/2026/06/gen-ai-performance-reports),
[Generative AI performance report (Search)](https://support.google.com/webmasters/answer/16984139),
[searchanalytics.query](https://developers.google.com/webmaster-tools/v1/searchanalytics/query)).
The same interface also splits Web into *Web: text-based* and *Web: multimodal* (Lens, Circle to
Search, image uploads); the API documents no such split (verified 2026-10-14 —
[Performance report](https://support.google.com/webmasters/answer/7576553)).

**Zero AI impressions → check the control before the content.** Settings → *Search generative AI*
is a per-property control: Include, Exclude, or inherit from the parent property. Include is
*"the default control for all properties"*, but inherit is *"the default if your property has a
parent property"* — so a child property follows its parent until someone overrides it.
Exclude removes the site's links and content from AI Overviews, AI Mode and Discover's generative
features. Google's help gives two reasons the report can be empty — too few impressions, or the
site excluded through this control — so read the setting, and on a URL-prefix property its
parent's, before calling it a content problem. It is not a ranking signal for the rest of Search
and does not control training; that is `Google-Extended` (verified 2026-10-14 —
[Search generative AI control](https://support.google.com/webmasters/answer/16908024)).

Measurement across engines, Bing's included, is in `15-geo-measurement.md`.

## What to hand the user

The API cannot act, so end a diagnosis with the two or three things only they can do, each with the
deep link `inspectionResultLink` gives you:

1. Open the affected report in Search Console and press **Validate Fix** after the change ships.
   Google says validation *"typically takes up to about two weeks, but in some cases can take much
   longer"* (verified 2026-10-14 — [Page indexing report](https://support.google.com/webmasters/answer/7440203)).
2. **Request indexing** on the handful of URLs that matter most.
3. Any dashboard-level change that no code change can reach — CDN redirect rules, a CDN-managed
   robots.txt (Cloudflare: AI bot policies with Bot Preference Sync), the Search generative AI
   control. After fixing robots.txt, the **robots.txt report** (Settings; domain-level properties
   only) can request a recrawl of the file (verified 2026-10-14 —
   [robots.txt report](https://support.google.com/webmasters/answer/6062598)).
