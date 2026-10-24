# GEO — Generative Engine Optimization

*Loaded by `site-triage` SKILL when user mentions AI search, ChatGPT, Claude Web, Perplexity, answer engines, or wants brand visibility in LLM-generated answers.*

> **Verified 2026-10-14 · review by 2026-12-13.** Claims that can rot carry their own date and
> source inline. A claim without one has not been checked — treat it as unverified, not as fact.

Traditional SEO ranks your site in 10 blue links. **GEO aims to get you cited inside AI-generated answers** (ChatGPT Search, Claude Web, Perplexity, Google AI Overviews, Bing Copilot).

**Set expectations before doing any of this.** GEO measurement exists now, but only per vendor and
only for outcomes: Bing Webmaster Tools reports citations, cited pages and grounding queries for
Copilot and Bing's AI summaries (public preview since 2026-02-10), and Search Console reports
impressions — not clicks — in AI Overviews and AI Mode (all sites since 2026-08-31). ⚠️ No
comparable report for ChatGPT, Claude or Perplexity was found in this pass (their crawler pages
document none; not otherwise searched), and neither report says which change moved the
number (verified 2026-10-14 — sources and detail in `15-geo-measurement.md`, "Outcome data").
Everything below is a plausible input, not a demonstrated lever. Say that to the user rather than
promising visibility.

## Core requirements (beyond classic SEO)

### 1. `llms.txt` — agent-facing, not a ranking lever

See `03-discoverability-classic.md`, which carries the honest framing and the sources: Google
says it is not needed for Search and does not affect visibility or rankings there (verified
2026-09-25), and crawler traffic to `/llms.txt` is reported to be negligible (⚠️ third-party
write-ups only). Ship it because it is cheap infrastructure for agents and
because Lighthouse's Agentic Browsing audit checks for it — never as a rankings argument.

Content rules, when you do ship one:
- **Factual, not promotional** — LLMs strip marketing language
- **Scannable** — short paragraphs, bullet lists, H2/H3 hierarchy
- **Entity-dense** — proper nouns, versions, dates inline
- **Linked** — pointers to GitHub, releases, docs (LLMs follow for verification)

### 2. Schema.org types — what Google still renders

**Do not ship `FAQPage` or `HowTo` for rich results. Both are dead on Google.**

| Type | Status | Source |
|---|---|---|
| `FAQPage` | Rich result removed from Search 2026-05-07; Search Console FAQ report and Rich Results Test support withdrawn (verified 2026-08-14). Documentation removed in June 2026 — the old `/structured-data/faqpage` URL now 301s to the updates log, which says the rich result *"is no longer shown in Google Search results"* | [Google — Search Central updates](https://developers.google.com/search/updates#removing-faq-rich-result) (verified 2026-10-14) |
| `HowTo` | Rich result gone on desktop and mobile; documentation removed 2023-09-14 — the old `/structured-data/how-to` URL now 301s to the updates log, whose 2023-09-14 entry says Google *"Removed the How-to structured data documentation, as this rich result is no longer shown in search results, on both desktop and mobile devices."* Absent from the current Search Gallery (verified 2026-08-14) | [Google — Search Central updates](https://developers.google.com/search/updates#how-to-deprecation) (verified 2026-10-14) |

Both remain valid schema.org vocabulary, and other consumers may parse them. That is not a reason
to add them: markup you cannot verify the effect of is markup you will keep maintaining for
nothing. If a site already ships them, leaving them costs nothing — say so and move on.

**What to ship instead**, all still rendered by Google (verified 2026-08-14 against the Search
Gallery): `Organization` (see `10-brand-serp.md` — this is the one that puts a logo in the SERP),
`Article` / `BlogPosting`, `BreadcrumbList`, `Product`, `SoftwareApplication`, `Event`, `Recipe`,
`VideoObject`.

Write answer-shaped content anyway — a heading that asks the question and a first paragraph that
answers it in two sentences. That helps extraction with no markup and nothing to maintain.

## E-E-A-T signals (Experience, Expertise, Authoritativeness, Trust)

AI engines check authority. Ship:

- **`Person` schema** for authors with full `sameAs`:
  ```json
  {
    "@type": "Person",
    "name": "NAME",
    "url": "https://MAINTAINER_URL",
    "sameAs": [
      "https://github.com/USER",
      "https://linkedin.com/in/USER",
      "https://twitter.com/USER",
      "https://bsky.app/profile/USER",
      "https://mastodon.social/@USER"
    ]
  }
  ```
- Explicit `datePublished` + `dateModified` on content pages
- Editorial transparency: About page, public changelog, methodology notes
- `sameAs` array on `Organization` — every social profile and code host

## Factual extraction patterns

Write content LLMs can pull verbatim:

- **TL;DR at top** — ≤3 sentences, extractable answer to "what is X?"
- **Definition-style headings** — "What is X?", "How does Y work?", "When to use Z?"
- **Fact tables with plain values** — no prose noise
- **Version + date stamps inline** — "As of v2.3, December 2025, X supports Y"
- **Canonical entity naming** — no pronouns far from their antecedent (LLMs lose the thread)
- **Short paragraphs** (≤4 sentences) — chunk-retrievable

## No JS-gated content

Most LLM crawlers do NOT execute JS. SSR or static-render everything critical. Dynamic content loaded post-hydrate is invisible to ChatGPT / Claude / Perplexity bots.

Verification:
```bash
curl -s https://DOMAIN/ | grep -c "important brand text"
# If 0, content is JS-hydrated → LLM won't see it
```

## Entity disambiguation

If your brand name collides with a common word, add disambiguating context everywhere:
- ❌ "PRODUCT works great"
- ✅ "PRODUCT, the open-source CATEGORY tool for PLATFORM, works great"

Prevents LLMs confusing you with unrelated matches. Critical for generic names.

## Testing GEO coverage

Quarterly, query each engine for brand + common intent:
- **ChatGPT** (chatgpt.com with web search on; `chat.openai.com` 308-redirects there, checked 2026-10-24) — "What is $BRAND?", "How do I install $BRAND?"
- **Claude.ai** — same
- **Perplexity** — same, check cited sources
- **Google AI Overview** — search brand + common query on google.com
- **Bing Copilot** — same via Bing

**Red flags**: brand absent from response, or misrepresented (wrong category, wrong platform).

**Fix actions when absent**:
- Update `llms.txt` content (richer, more factual)
- Add an answer-shaped section covering the query topic — question as the heading, answer in the
  first two sentences. No `FAQPage` markup; see above for why
- Check backlinks — LLMs often cite via backlink graph
- Verify no JS-gated content blocking crawlers

## GEO-specific validator

**Measure before recommending.** `15-geo-measurement.md` covers GeoDaddy — open-source, fully
local, available to this plugin as an MCP tool (`analyze_url`, 22 checks) and as a CLI (`v0.8.0`,
56 checks including an `agent-` category) (verified 2026-10-14 — check IDs counted in the tool's
source at both tags). The two paths are not comparable; say which one produced a score. Run it
before proposing GEO work and again after, and report the delta rather than a single number.

Note the deliberate disagreements: `geo-schema-stacking` wants `FAQPage`, and the CLI adds
`geo-faq-quality` (wants `FAQPage`) and `geo-howto-schema` (wants `HowTo`), both of which this
skill drops for the reasons given above. Report the lost points as a choice, not as a defect.

The hosted Cloudflare scanner https://isitagentready.com/ overlaps with agent-ready (see
`06-agent-ready.md`). Its own `/llms.txt` says it checks `llms.txt` and `llms-full.txt` under
Content Accessibility, but its documented API (`POST /api/scan`) returned 22 checks on
2026-10-14 with markdown negotiation as the only Content Accessibility check (verified
2026-10-14 — [isitagentready.com/llms.txt](https://isitagentready.com/llms.txt) and a scan of
`https://example.com`). Do not rely on it to confirm an `llms.txt`; fetch the file yourself.

Manual test every 90 days: ask each AI engine the brand query, paste response here for gap analysis.
