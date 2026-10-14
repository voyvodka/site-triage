# GEO measurement — scoring a site with GeoDaddy

*Loaded by `web-launcher` SKILL whenever GEO work is proposed, and in any Mode B audit that touches
AI-search visibility. This is the measurement half of `04-geo.md`, which is the advice half.*

> **Verified 2026-10-14 · review by 2026-12-13.** Versions, tool names and check IDs were read
> from the tool's own repository and the npm registry on that date.

## Why this exists

`04-geo.md` recommends GEO work. Two first-party outcome reports now exist — Bing's AI Performance
and Search Console's generative AI report, both covered under "Outcome data" below — but they cover
Microsoft and Google surfaces only and say nothing about which input moved the number. ⚠️ No
site-owner report from ChatGPT, Claude or Perplexity was found in this pass — their crawler pages
document none; nothing else was searched. A recommendation nobody can score is a
recommendation nobody can defend.

[GeoDaddy](https://geodaddy.dev/) closes the input side of that gap. It is an **open-source (MIT),
fully local** analyzer — no account, no API key, no cloud round-trip — that returns a scored JSON
report with fix recommendations. How many checks it runs depends on which path you use: the MCP
path's `0.2.2` analyzer defines **22 checks** in three categories plus five Core Web Vitals checks
behind `--vitals`; the `v0.8.0` CLI defines **56 checks** in four categories — the extra one is
`agent-` — plus the same five vitals checks (verified 2026-10-14 — check IDs counted in the
[source](https://github.com/borabiricik/geodaddy-cli) at tags `v0.2.2` and `v0.8.0`). The `v0.8.0`
README still says "4 categories"; the source scores five.

**What it actually measures: the inputs, not the outcome.** It scores whether a page carries the
signals believed to drive AI citation. It cannot tell you whether ChatGPT cites you. Say that to
the user before showing a score, or the number will be read as visibility.

## Two ways in — pick per task

| Path | Use when | Cost |
|---|---|---|
| **MCP server** — this plugin declares `geodaddy` in its `.mcp.json` | Interactive audits. The `analyze_url` tool returns a structured report the model can reason over directly | First run pulls `geodaddy-mcp@0.2.2` via `npx` — the version is **pinned** in `.mcp.json`, so a new upstream publish does not silently change what runs; the wrapper then downloads the binary from GitHub releases |
| **CLI** — `geodaddy <URL>` | CI, scripted runs, anything reproducible. Single binary, no runtime dependency | One-time install |

```bash
# install (macOS/Linux)
curl -fsSL https://raw.githubusercontent.com/borabiricik/geodaddy-cli/main/install.sh | sh
geodaddy --version

geodaddy https://example.com --beauty              # human-readable
geodaddy https://example.com                       # JSON, for CI
geodaddy https://example.com --max-pages 50        # crawl the site
geodaddy https://example.com --vitals              # + Core Web Vitals (downloads Chromium ~150 MB)
geodaddy compare https://mysite.com https://rival.com --beauty
```

**Version drift — measured, not assumed.** The standalone CLI is `v0.8.0` (released 2026-07-06,
still the latest release and the latest commit on 2026-10-14 — `gh release list`). The npm wrapper
`geodaddy-mcp` is `0.2.2` (published 2026-03-25), still `latest` and one of only two versions ever
published (verified 2026-10-14 — `npm view geodaddy-mcp`), and **the analyzer binary it downloads
reports `geodaddy 0.2.2`** — checked by running the bundled binary directly (2026-08-14). The MCP
path returned 21 results for `https://example.com` on 2026-10-14 — the missing one was
`tech-heading-hierarchy`, on a page with no headings. So the MCP path runs an analyzer more than three months and
over thirty checks behind the CLI. When a number matters, prefer the CLI and say which path
produced the score — the two are not comparable.

## Scoring model — read this before quoting a number

- Severity → points: **Critical 10 · Medium 5 · Minor 2**. Pass earns full, **warn earns half**,
  fail earns zero.
- Category score = points earned ÷ points possible × 100.
- Overall = mean of the category scores, so it depends on the path: **MCP `0.2.2`** averages
  Technical, Content, GEO; **CLI `v0.8.0`** averages Technical, Content, GEO **and Agent**. Either
  adds Performance only when `--vitals` ran (verified 2026-10-14 — `src/scoring.rs` at `v0.8.0`).
- **A category with no applicable checks scores 100.** A site can post a high overall while a whole
  category was never exercised. Always report which categories actually ran.

The categories: `tech-` (meta, headings, HTTPS, redirects, robots, sitemap, broken links), `cont-`
(heading structure, alt text, JSON-LD, semantic HTML), `geo-` (listicle formatting, AI bot access,
schema stacking — and in `v0.8.0` also citations, entities, freshness, FAQ/HowTo, `llms.txt`,
query-shaped content), `agent-` (`v0.8.0` only: Link headers, markdown negotiation, Content
Signals, Web Bot Auth, MCP server card, OAuth discovery, commerce protocols — the ground
`06-agent-ready.md` covers), `perf-` (Core Web Vitals, `--vitals` only).

## Where this tool and this skill disagree

**Treat these as known divergences, not as findings.** Do not "fix" a site to raise a score when
the fix contradicts a sourced position — say which one you are optimizing for and let the user
choose.

| Check | GeoDaddy expects | This skill's position |
|---|---|---|
| `geo-schema-stacking` (Medium, 5 pts) | `Article` **+ `ItemList` + `FAQPage`** all present | `FAQPage` was dropped: Google removed the rich result 2026-05-07 and deleted the documentation page. See `04-geo.md`. **Following this skill costs points here.** |
| `geo-faq-quality` (Minor, 2 pts — `v0.8.0` only) | `FAQPage` JSON-LD with 40–60-word answers | Same divergence. With no `FAQPage` the check returns **Warn**, so the cost is half its points, not all of them (verified 2026-10-14 — `src/analyzers/geo_citations.rs`, `src/scoring.rs` at `v0.8.0`) |
| `geo-howto-schema` (Medium, 5 pts — `v0.8.0` only) | `HowTo` JSON-LD; its recommendation claims HowTo *"enables rich results"* | `HowTo` is absent from Google's Search Gallery (see `04-geo.md`). Absence returns **Warn** — half the points (verified 2026-10-14 — `src/analyzers/geo_freshness.rs` at `v0.8.0`). Do not add markup for steps a page does not have |
| `geo-ai-bot-*` (Critical, 10 pts each) | `GPTBot`, `ClaudeBot`, `PerplexityBot`, `GoogleOther`, `Bytespider`, `CCBot` not blocked | Right that a catch-all `Disallow` is expensive — six critical checks, 60 points. **But five of the six tokens it checks — all but `PerplexityBot` — are training or generic crawlers, not the retrieval crawlers that decide citation** (verified 2026-10-14 — the same six tokens in `src/analyzers/geo.rs` at both `v0.2.2` and `v0.8.0`). See below |
| `geo-listicle` (Medium) | Numbered headings, "Top N" patterns, ordered lists, comparison tables | Reasonable as a formatting heuristic. It scores *shape*, not usefulness — do not restructure good prose into a listicle purely for this |
| `agent-*` (`v0.8.0` only; 16 checks, 2–5 pts each) | Link headers, markdown negotiation, MCP server card, Content Signals, Web Bot Auth, OAuth discovery, A2A card, WebMCP, x402/MPP/UCP/ACP/AP2 | `06-agent-ready.md` rates most of these as declarations with no measured effect, and WebMCP and the commerce protocols are out of this plugin's scope. Report the Agent score; do not build surfaces to raise it |

The `FAQPage` conflict is the one that will come up. Both positions are defensible: GeoDaddy scores
for AI extraction across engines, this skill declines markup Google no longer renders. **Report the
score, name the divergence, and let the user decide** — do not silently re-add `FAQPage` to chase a
number, and do not hide that the number is lower because of a deliberate choice.

### The training-vs-retrieval error — do not act on this one

When `geo-ai-bot-gptbot` fails, GeoDaddy reports: *"GPTBot is blocked in robots.txt. This prevents
your content from appearing in ChatGPT search results."* (verified 2026-10-14 — the message
template in `src/analyzers/geo.rs`, unchanged between `v0.2.2` and `v0.8.0`). **That sentence is
wrong**, and acting on it reverses a policy the site may hold deliberately.

OpenAI's own documentation, verified 2026-10-14
([Overview of OpenAI Crawlers](https://developers.openai.com/api/docs/bots)):

| Token | What it actually does |
|---|---|
| `GPTBot` | **Training only.** *"Disallowing GPTBot indicates a site's content should not be used in training generative AI foundation models."* |
| `OAI-SearchBot` | **Search.** *"Sites that are opted out of OAI-SearchBot will not be shown in ChatGPT search answers"* — they can still appear as navigational links |
| `ChatGPT-User` | User-initiated fetches; *"not used to determine whether content may appear in Search"*, and *"Because these actions are initiated by a user, robots.txt rules may not apply."* |
| `OAI-AdsBot` | **Ads only.** *"used to validate the safety of web pages submitted as ads on ChatGPT"*; visits only pages submitted as ads, and its data is not used for training. Irrelevant to citation |

So **blocking `GPTBot` costs you nothing in ChatGPT search** — that is `OAI-SearchBot`'s job.

The same split exists for Anthropic and for Google, and the tokens are easy to mix up. Verified
2026-10-14 against each vendor's own documentation:

| Token | What it actually does | Source |
|---|---|---|
| `ClaudeBot` | **Training.** *"collecting web content that could potentially contribute to their training"* | [Anthropic crawler support article](https://support.claude.com/en/articles/8896518-does-anthropic-crawl-data-from-the-web-and-how-can-site-owners-block-the-crawler) |
| `Claude-User` | User-initiated fetches — *"When individuals ask questions to Claude, it may access websites using a Claude-User agent"* | same |
| `Claude-SearchBot` | **Search.** *"navigates the web to improve search result quality for users"* | same |
| `Google-Extended` | **Training + grounding opt-out** for Gemini/Vertex. *"does not impact a site's inclusion in Google Search nor is it used as a ranking signal"* | [Google's common crawlers](https://developers.google.com/crawling/docs/crawlers-fetchers/google-common-crawlers) (moved from `/search/docs/crawling-indexing/`; the old URL 301s) |
| `GoogleOther` | **Neither.** A generic agent *"used by various product teams for fetching publicly accessible content… one-off crawls for internal research and development"* | same |

### Crawlers that honour `robots.txt` and fetchers that may not

A `Disallow` only governs the crawlers that read it. Every vendor below now documents the difference
between its automatic crawlers and the fetchers a user's request triggers. Verified 2026-10-14
against each vendor's page:

| Vendor | Search / citation crawler | User-triggered fetcher — and what the vendor says about `robots.txt` | Source |
|---|---|---|---|
| OpenAI | `OAI-SearchBot` | `ChatGPT-User` — *"robots.txt rules may not apply"* | [OpenAI crawlers](https://developers.openai.com/api/docs/bots) |
| Anthropic | `Claude-SearchBot` | `Claude-User` — the article states Anthropic's bots *"respect 'do not crawl' signals by honoring industry standard directives in robots.txt"*, with no exception for `Claude-User` | [Anthropic article](https://support.claude.com/en/articles/8896518-does-anthropic-crawl-data-from-the-web-and-how-can-site-owners-block-the-crawler) |
| Perplexity | `PerplexityBot` — *"designed to surface and link websites in search results on Perplexity"* | `Perplexity-User` — *"this fetcher generally ignores robots.txt rules"* | [Perplexity Crawlers](https://docs.perplexity.ai/docs/resources/perplexity-crawlers) (the old `/guides/bots` URL 301s here) |
| Meta | `Meta-WebIndexer` — *"navigates the web to improve Meta AI search result quality"*; allowing it *"helps us cite and link to your content in Meta AI's responses"* | `Meta-ExternalFetcher` — *"this crawler may bypass robots.txt rules"* | [Meta Web Crawlers](https://developers.facebook.com/documentation/sharing/webmasters/web-crawlers) |
| Google | `Googlebot` — the common-crawlers page lists no separate AI-search token | `Google-Agent` — *"used by agents hosted on Google infrastructure to navigate the web and perform actions upon user request"*, experimenting with Web Bot Auth as `https://agent.bot.goog` — and the other user-triggered fetchers, which *"generally ignore robots.txt rules"* | [Google user-triggered fetchers](https://developers.google.com/crawling/docs/crawlers-fetchers/google-user-triggered-fetchers) |

Two consequences. Blocking a user-triggered fetcher in `robots.txt` states a preference that four
of these five vendors say they may not honour — enforcement needs a WAF rule, not a `Disallow`. And
allowing it is not the same as being citable: citation in search answers runs through the
crawler in the second column.

Two things follow, and GeoDaddy gets both wrong:

- **`ClaudeBot` is the training crawler, not the retrieval one.** Allowing it does not make a site
  citable in Claude; that is `Claude-SearchBot` and `Claude-User`. A site that blocks `ClaudeBot`
  and allows those two is opted out of training and fully available for citation — GeoDaddy scores
  it as a failure anyway.
- **`GoogleOther` is not a training control at all**, so blocking it neither protects the site from
  training use nor costs it Search visibility. The Gemini training opt-out is `Google-Extended`,
  which GeoDaddy does not check.

A site that allows retrieval crawlers (`OAI-SearchBot`, `ChatGPT-User`, `Claude-SearchBot`,
`Claude-User`, `PerplexityBot`, `Meta-WebIndexer`) while blocking training crawlers (`GPTBot`, `ClaudeBot`, `CCBot`,
`Google-Extended`, `Bytespider`) holds a coherent position: *cite me, do not train on me.* GeoDaddy
scores exactly that as multiple critical failures, because it checks the training tokens and calls
them citation blockers.

**What to do:** report the lost points, state that the failures are a stated policy rather than a
misconfiguration, and then check the tokens that actually decide citation — none of which GeoDaddy
scores. A `grep` for the token names cannot answer this: it prints `User-agent:` lines, never the
`Disallow:` under them, and it prints nothing at all when a `User-agent: *` group blocks
everything. Resolve each token to the group that governs it — its own group if one names it,
otherwise `*` — and read that group's root rule:

```bash
robots=$(mktemp)
if ! curl -sf --max-time 20 "https://DOMAIN/robots.txt" > "$robots"; then
  echo "?    robots.txt unreachable or not 200 — check did not run"
else
  for bot in OAI-SearchBot ChatGPT-User Claude-SearchBot Claude-User PerplexityBot Meta-WebIndexer; do
    awk -v bot="$bot" '
      BEGIN { b = tolower(bot) }
      { line = $0; sub(/#.*/, "", line); gsub(/\r/, "", line); l = tolower(line) }
      l ~ /^[ \t]*user-agent[ \t]*:/ {
        ua = l; sub(/^[^:]*:[ \t]*/, "", ua); sub(/[ \t]+$/, "", ua)
        if (!run) { mine = 0; star = 0 }
        run = 1
        if (ua == b) { mine = 1; named = 1 }
        if (ua == "*") star = 1
        next
      }
      l ~ /^[ \t]*disallow[ \t]*:[ \t]*\/[ \t]*$/ { if (mine) md = 1; if (star) sd = 1 }
      l ~ /^[ \t]*allow[ \t]*:[ \t]*\/[ \t]*$/    { if (mine) ma = 1; if (star) sa = 1 }
      l ~ /[^ \t]/ { run = 0 }
      END {
        blocked = named ? (md && !ma) : (sd && !sa)
        printf "%s %s — %s group\n", blocked ? "FAIL" : "OK  ", bot, named ? "own" : "\"*\""
      }' "$robots"
  done
fi
rm -f "$robots"
```

`OK` on all six means no root-level `Disallow` reaches the citation crawlers, regardless of the
score. Path-level rules (`Disallow: /private/`) are not judged here — they block pages, not the
site. A `FAIL` on `ChatGPT-User` reports the site's stated preference, not access: OpenAI says
`robots.txt` rules may not apply to it (table above). Report this result, not the score, when the
user asks whether they are visible to AI search. Only recommend unblocking training crawlers
if the user actually wants to be trained on, and say that is what the change means.

Bytespider is a related case: GeoDaddy treats blocking it as critical, while `03-discoverability-classic.md`
notes it is widely reported to ignore `robots.txt` anyway. Allowing it earns the points and denies
nothing in practice; just do not describe blocking it as a control.

## Where it overlaps `14-diagnostic-checks.md`

`tech-redirect-chains`, `tech-robots-txt`, `tech-sitemap-xml`, `tech-https` cover ground the
diagnostic checks also cover — but as **pass/fail scores, not as diagnoses.** GeoDaddy says a
redirect chain exists; C1/C4 say which URL, how many hops, and which file causes it.

**Order of operations:** GeoDaddy first for the scored picture, `14-diagnostic-checks.md` for
anything it flags that needs a cause. Never report a GeoDaddy failure as a finding without tracing
it to a file or a dashboard setting.

## Outcome data — what Bing and Google now report

GeoDaddy scores inputs. Two vendors now report outcomes for their own AI surfaces. Neither covers
ChatGPT, Claude or Perplexity, and neither says which change moved a number — read them alongside
the GeoDaddy delta, never instead of it.

**Bing Webmaster Tools — AI Performance** (public preview since 2026-02-10). Covers citations in
Microsoft Copilot, AI-generated summaries in Bing and select partner integrations. Reports total
citations, average cited pages per day, page-level citation counts, grounding queries (*"the key
phrases the AI used when retrieving content that was referenced in AI-generated answers"*) and
trends over time. It does not
measure ranking, placement or a page's role in an answer, and the announcement mentions no clicks
or traffic. Grounding queries are *"a sample of overall citation activity"*, not a full log
(verified 2026-10-14 — [Introducing AI Performance in Bing Webmaster Tools Public Preview](https://blogs.bing.com/webmaster/February-2026/Introducing-AI-Performance-in-Bing-Webmaster-Tools-Public-Preview)).
Preview additions since: Intents, Topics, Citation Share (your share of all citations shown) and
Compare (verified 2026-10-14 — [New AI Visibility Insights in Bing Webmaster Tools](https://blogs.bing.com/search/June-2026/New-AI-Visibility-Insights-in-Bing-Webmaster-Tools-Intents-Topics-Citation-Share-Compare),
2026-06-16), and **Topics Portfolio (beta)**, which groups grounding queries into themes with
demand and competition, and appears only *"If there is sufficient data for your site"* — small
sites may see nothing (verified 2026-10-14 — [Introducing Topics Portfolio (Beta) in AI Performance](https://blogs.bing.com/webmaster/2026/10/introducing-topics-portfolio-beta-in-ai-performance/),
2026-10-13). The announcement documents no API for this data. It is the only first-party citation report
this pass found; use it as the outcome measure for GEO work where the site is verified in Bing
Webmaster Tools.

**Google Search Console — Generative AI performance report** (launched 2026-06-03, rolled out to
all sites 2026-08-31). **Impressions only** — *"how often URLs from your site appeared in
generative AI features"* — for AI Overviews and AI Mode, with a separate Discover report, broken
down by page, country, device and date. No clicks and no citation position (verified 2026-10-14 —
[Introducing Search Generative AI performance reports](https://developers.google.com/search/blog/2026/06/gen-ai-performance-reports);
[help: generative AI performance report](https://support.google.com/webmasters/answer/16984139)).
The help page documents an export button in the report; whether the data is reachable through the
Search Console API is owned by `16-search-console.md` — read it there rather than assuming.

## Reporting

Report the category scores that actually ran, and which path produced them, then **what changed
since the last run** if there is a previous report — a single score is a number, a delta is
evidence. Re-run after every fix and show both. Where the user has Bing Webmaster Tools or Search
Console access, put the citation or impression trend for the same period beside the delta.

Never present the overall score as AI-search visibility. It is a signal checklist, and it says so.
