# Agent-Ready discoverability (2025–2026 standards)

*Loaded by `web-launcher` SKILL when user mentions `isitagentready.com`, agentic web, MCP-facing sites, or wants programmatic agent discovery.*

> **Verified 2026-10-14 · review by 2026-12-13.** Claims that can rot carry their own date and
> source inline. A claim without one has not been checked — treat it as unverified, not as fact.
>
> One of the four signals this file covers — `Content-Signal`, with its AIPREF draft counterpart
> `Content-Usage` — has **almost no effect on crawlers today**: Cloudflare's own `/crawl` endpoint
> is its one documented consumer, and nothing is known to parse `Content-Usage`. Web Bot Auth
> does nothing without real keys. Read the priority matrix before recommending anything here. Claims re-read on 2026-10-14 carry that
> date; a few rows keep an earlier one where today's pass did not re-read the source.

Parallel to classic SEO and GEO, a new discovery layer is forming: **AI agents that programmatically consume your site** (ChatGPT tool use, Perplexity retrieval, Claude MCP servers, custom enterprise bots). This file covers four signals for that layer — different surface from classic crawlers.

**Cloudflare's `isitagentready.com` scanner is broader than this file.** It now runs **22 checks in
five categories** — Discoverability, Content Accessibility, Bot Access Control, API/Auth/MCP
Discovery, Commerce — and documents an API (`POST /api/scan` with `{"url": "https://DOMAIN"}`;
add `"format": "agent"` for one combined fix prompt) and an MCP server at
`https://isitagentready.com/mcp` (verified 2026-10-14 — [isitagentready.com/llms.txt](https://isitagentready.com/llms.txt)
and a `POST /api/scan` of `https://example.com`). Most of its extra checks — DNS-AID, `auth.md`,
OAuth discovery, MCP Server Card, A2A Agent Card, agent skills, WebMCP, the ARD capability manifest
and the commerce protocols (x402, MPP, UCP, ACP, AP2) — are agent surfaces this plugin has
**parked**: name them when the scanner flags them, do not build them. Commerce checks return
`neutral` on a site that is not a store.

Its own description and its output disagree on `llms.txt`: the `/llms.txt` lists `llms.txt` and
`llms-full.txt` under Content Accessibility, while the scan returned markdown negotiation as the
only Content Accessibility check. Fetch `/llms.txt` yourself rather than citing the scanner.

**Hosted readiness check**: `https://isitagentready.com/?url=YOUR_DOMAIN` (⚠️ the `?url=` form is
not documented in its `llms.txt`; the API above is)

## The four signals this file covers (in priority order)

**Only signal 1 is "always".** `Link:` headers are ratified and actually parsed; the priority matrix
near the end of this file rates its *Skip if* as "Never". The other three are governed by that
matrix. Signal 2 has almost no technical effect today: `Content-Signal` has one documented
consumer, Cloudflare's own `/crawl` endpoint, and its AIPREF counterpart `Content-Usage` (covered
under signal 2) has none — ship them when the user wants to state intent or wants a scanner green,
and say which of the two you are doing. Web Bot Auth is worth it only with real keys and real outbound signing.

### 1. `Link:` response headers (RFC 8288)

Agents prefer machine-discoverable entrypoints over scraping HTML. Emit `Link` on the homepage and
key routes.

**Not every `rel` below is registered.** Checked against the IANA Link Relations registry CSV on
2026-10-14 ([registry](https://www.iana.org/assignments/link-relations/)): `alternate`,
`describedby`, `api-catalog`, `service-doc` and `service-desc` are registered; **`sitemap` and
`security-txt` are not**. They are conventions some scanners look for, not standard relations —
keep them if the scanner matters to the user, and never describe them as IANA-registered.

**Point at `llms.txt` with `rel="describedby"`, not `alternate`.** The llms.txt v2 proposal
(modified 2026-08-10) splits the two: `rel="alternate" type="text/markdown"` points to *a page's
own* markdown version, and `rel="describedby"` points to the `llms.txt` that covers it — and an
`llms.txt` covers every page under its path (verified 2026-10-14 — [llmstxt.org](https://llmstxt.org/)).
Earlier versions of this file used `alternate` for `llms.txt`; that now says the home page *is*
the `llms.txt`.

```http
Link: </llms.txt>; rel="describedby"
Link: </index.md>; rel="alternate"; type="text/markdown"
Link: </sitemap.xml>; rel="sitemap"
Link: </.well-known/security.txt>; rel="security-txt"
Link: </api/catalog.json>; rel="api-catalog"
Link: </docs/api>; rel="service-doc"
Link: </openapi.json>; rel="service-desc"
```

Emit the `alternate` line only on routes that actually have a markdown twin, and point it at that
route's own file.

**Cloudflare Pages / Workers `_headers`** (simplest):
```
/*
  Link: </llms.txt>; rel="describedby", </sitemap.xml>; rel="sitemap", </.well-known/security.txt>; rel="security-txt"
```

**Express / Node middleware**:
```ts
app.use((_req, res, next) => {
  res.setHeader("Link", [
    `</llms.txt>; rel="describedby"`,
    `</sitemap.xml>; rel="sitemap"`,
    `</.well-known/security.txt>; rel="security-txt"`,
  ].join(", "));
  next();
});
```

**Audit**: `curl -sI https://DOMAIN/ | grep -i "^link:"`

### 2. `Content-Signal` directive in `robots.txt`

> **Reality check.** Only one crawler is documented to act on this, and it is Cloudflare's own:
> the Browser Run `/crawl` endpoint enforces the `search` / `ai-input` / `ai-train` purposes and,
> since 2026-08-31, the `use` level — a crawl whose declared purpose or level the site's
> `robots.txt` rules out is rejected with a `400` (verified 2026-10-14 — [Crawl endpoint: Content
> Signals](https://developers.cloudflare.com/browser-run/quick-actions/crawl-endpoint/#content-signals),
> [changelog 2026-08-31](https://developers.cloudflare.com/changelog/post/2026-08-31-crawl-content-use/)).
> No search engine or AI lab is known to act on it. A member of Google's Search Relations team, July 2026: *"AFAIK none
> of the crawlers / llms use the content-signal robots.txt directives"* and *"It was made up by a
> CDN, afaik it has no effects whatsoever for any crawler or llm."* ⚠️ Sourced from secondary
> write-ups quoting him ([1](https://searchengineoptimization.blog/article/google-says-cloudflares-content-signals-tag-does-nothing),
> [2](https://www.tryvizup.com/blog/cloudflare-content-signals-what-google-actually-said)); the
> original thread could not be reached directly (2026-08-14).
>
> Cloudflare stamping this on millions of domains via managed robots.txt is **publisher-side**
> adoption, not crawler-side. Those are different claims and this file used to conflate them.
> An earlier version also called it "IANA-compatible" — that could not be sourced against any IANA
> registry and has been removed.
>
> **Ship it as a statement of intent, not as a control.** It is free and may matter for
> copyright posture. Outside Cloudflare's own crawl API it changes no crawler's behaviour today.
> Never present it to a user as protection.

Cloudflare 2025 robots.txt extension. Declares preference for how AI systems may use your content — independent of `Allow`/`Disallow`. **Not a hard block; a policy signal.**

**Watch for edge injection.** On Cloudflare, **Bot Preference Sync** generates managed
`robots.txt` directives from the zone's Search, Agent and Training AI bot policies when the
*Enable Bot Preference Sync* toggle is on and at least one policy is set to *Block*, *Block on
pages with ads* or (Training) *Disallow*, merging them into the origin's file or creating one. With
sync on, Training *Disallow* also turns on edge blocking for AI training crawlers, mixed-use
crawlers excluded. The managed block carries `Content-signal: search=yes, ai-train=no,
use=reference` and Cloudflare's Content Signals Policy comment text, which can invert what the
repository declares. **Free-plan zones with no `robots.txt` of their own and no managed setting are
served the Content Signals Policy text** — definitions only, no preferences. Search Console may
report `Syntax not understood` on these lines; Cloudflare says it has observed no crawl or SEO
impact (verified 2026-10-14 — [robots.txt setting](https://developers.cloudflare.com/bots/additional-configurations/managed-robots-txt/),
last updated 2026-10-08). Always diff live against repo — see `14-diagnostic-checks.md` C2.

Cloudflare's page for the legacy *Block AI bots* toggle says that on **2026-09-15** it would be
deprecated and new domains would get Training and Agent bots blocked on pages that display ads,
Search allowed. That is per Cloudflare's page, written ahead of the date (last updated
2026-07-01, still future tense on 2026-10-14); it is not confirmed as switched (verified
2026-10-14 — [Block AI Bots](https://developers.cloudflare.com/bots/additional-configurations/block-ai-bots/)).
For a domain added after that date, check the AI bot policies in the dashboard rather than
assuming the old default.

**Existing zones are affected too.** The same page says that from that date *"Mixed-purpose
crawlers that combine Search and Training will also be blocked by all configurations to block AI
training, including the legacy 'Block AI bots' option"* — so a zone that switched the old toggle on
years ago may now block crawlers that also feed search, where before the toggle excluded them.
Cloudflare's changelog says only that such crawlers *"will be affected by the new defaults to block
Training"* and does not mention the legacy toggle. Same caveat: written ahead of the date, not
confirmed as switched (verified 2026-10-14 — [Block AI Bots](https://developers.cloudflare.com/bots/additional-configurations/block-ai-bots/);
[New options to manage AI traffic](https://developers.cloudflare.com/changelog/post/2026-07-01-ai-traffic-options/)).
On a zone with the legacy toggle on, check which mixed-purpose crawlers it now blocks before
diagnosing a missing AI-search presence anywhere else.

```
Content-Signal: search=yes, ai-train=yes, ai-input=yes
```

Three established axes:
- **`search`** — classic crawler indexing (Googlebot, Bingbot)
- **`ai-train`** — model training datasets (CCBot, GPTBot training crawls)
- **`ai-input`** — real-time AI assistant retrieval (ChatGPT-User, Claude-User)

A fourth, **`use=immediate|reference|full`**, is in testing: how much a crawler may keep after
access. **Two Cloudflare pages define the levels differently.** The robots.txt setting page:
`immediate` *"Interact, but store and reuse nothing"*, `reference` *"Index, excerpt, and link
back"*, `full` *"Summarize and reproduce"*. The `/crawl` page: `immediate` *"Ephemeral,
single-response use, where content is not retained"*, `reference` *"Content may be retained,
indexed, or cited"*, `full` *"Unrestricted use, including AI training"*. Cloudflare adds
`use=reference` to managed `robots.txt` files (verified 2026-10-14 — [robots.txt
setting](https://developers.cloudflare.com/bots/additional-configurations/managed-robots-txt/);
[Crawl endpoint: Content Signals](https://developers.cloudflare.com/browser-run/quick-actions/crawl-endpoint/#content-signals),
last updated 2026-10-10). Only Cloudflare's `/crawl` is documented to enforce it, and its
`contentUse` accepts only `reference` or `full` (default `full`), so **`use=immediate` rejects
every `/crawl` request** and `use=reference` rejects the default one. Leave it out of a
hand-written file unless the user wants to state that preference, and never write
`use=immediate` without saying it shuts Cloudflare's crawler out entirely.

**Decision matrix — pick row matching site type**:

| Content type | `search` | `ai-train` | `ai-input` |
|---|---|---|---|
| Open marketing / portfolio / docs / OSS | yes | yes | yes |
| Paid journalism / proprietary research | yes | **no** | yes |
| Premium education (course content) | yes | **no** | yes |
| Legal / medical (attribution-critical) | yes | no | **no** |
| Staging / draft / internal | **no** | **no** | **no** |

For most marketing / portfolio / OSS sites: **`yes, yes, yes`** — maximum LLM citation visibility.

**Audit**: `curl -s https://DOMAIN/robots.txt | grep -i "^content-signal:"`

#### `Content-Usage` — the IETF AIPREF successor (emit alongside `Content-Signal`)

`Content-Signal` was Cloudflare's 2025 proposal. The **IETF AI Preferences WG (AIPREF)** put the same idea on the standards track as **`Content-Usage`**.

> **Status, re-verified 2026-10-14.** The draft that defines the robots.txt field and the HTTP
> header, `draft-ietf-aipref-attach`, expired at `-04` and revived: `-05` was submitted 2026-08-19
> and is still the current revision, an active Internet-Draft in the AIPREF WG, intended status
> Proposed Standard, expiring 2027-02-20. The vocabulary draft `draft-ietf-aipref-vocab` is still
> at **`-08`** (dated 2026-09-14, expiring 2027-03-18)
> ([Datatracker](https://datatracker.ietf.org/doc/draft-ietf-aipref-attach/), read via the
> Datatracker API on 2026-10-14). **Still no RFC published by this working group** —
> `std_level` is null on both documents.
>
> Consequence: the working group is alive, but nothing has shipped. The field name and syntax
> can still change, and **no crawler is known to parse `Content-Usage` today**. Emitting it is
> harmless and a defensible bet; still describe it as an active draft, never as a ratified standard
> or as protection.
>
> The `-05` text was read on 2026-10-14 and the examples below match it: the header is a
> structured-field dictionary (RFC 9651), and the robots.txt rule sits inside a `User-Agent` group,
> optionally with a path prefix, longest match winning (verified 2026-10-14 —
> [draft-ietf-aipref-attach-05](https://www.ietf.org/archive/id/draft-ietf-aipref-attach-05.txt),
> §1.2, §3.4).

Two delivery surfaces, same vocabulary:

```
# robots.txt rule — inside a group; optional path prefix, longest-prefix match like Allow/Disallow
User-Agent: *
Allow: /
Content-Usage: train-ai=n
Content-Usage: /ai-ok/ train-ai=y
```
```http
# HTTP response header (RFC 9651 structured-field dictionary)
Content-Usage: train-ai=n
```

**Vocabulary** (`draft-ietf-aipref-vocab-08`, Proposed Standard track) defines **three**
categories, each `y`/`n` (verified 2026-09-25 — the `-08` text, §4 and its label table; `-07`
had only the first and last):

| Category | Label | Meaning |
|---|---|---|
| AI Training | `train-ai` | using assets to produce/refine a generative AI model |
| AI Use | `ai-use` | *"Using an asset as input to a generative AI model, where the asset is not directly provided by the user"* — new in `-08` |
| Search | `search` | indexing assets to direct users to them (classic search) |

`ai-use` is the first AIPREF counterpart to the `ai-input` axis in Cloudflare `Content-Signal`.
It is one revision old and the draft carries an open issue on whether "direct" covers assets
referenced by URL (issue 249), so treat the mapping as provisional. The policy
`search=yes, ai-train=no, ai-input=yes` maps to `Content-Usage: search=y, train-ai=n, ai-use=y`.
Keep `Content-Signal` alongside it — no crawler is known to parse either.

**Caveat**: AIPREF drafts are not yet a ratified RFC (they expire-and-revise between WG revisions). Emit `Content-Usage` as an early-adopter, forward-compatible signal — do **not** drop `Content-Signal` for it yet.

**Audit**: `curl -s https://DOMAIN/robots.txt | grep -i "^content-usage:"`

### 3. Markdown for Agents (`Accept: text/markdown` content negotiation)

Agents that parse content prefer clean markdown over HTML — fewer tokens, no CSS/JS noise, stable structure. On `Accept: text/markdown` requests return markdown; keep HTML default for browsers.

**Cloudflare zones**: the *Markdown for Agents* toggle (AI Crawl Control, or a Configuration Rule
per host/path) converts HTML at the edge. It is **paid-plan only** — *"available to Pro, Business
and Enterprise plans, and SSL for SaaS customers at no cost"* — Free is not in that list, so on
Free use the self-hosted middleware below or emit static `.md` twins per route (verified
2026-10-14 — [Markdown for Agents](https://developers.cloudflare.com/fundamentals/reference/markdown-for-agents/)).
Converted responses get `Content-Type: text/markdown; charset=utf-8` and `Vary: Accept`. Since
**2026-10-09** they **no longer carry `x-markdown-tokens` or `x-original-tokens`** — clients count
tokens themselves (verified 2026-10-14 — [changelog 2026-10-09](https://developers.cloudflare.com/changelog/post/2026-10-09-markdown-for-agents-in-process-conversion/)).

**Gotcha — it can contradict §2.** When the origin sends no `Content-Signal` header, the converted
response gets `Content-Signal: ai-train=yes, search=yes, ai-input=yes` — even on a site whose
`robots.txt` says `ai-train=no`. Set the header at the origin; Cloudflare preserves it (verified
2026-10-14 — same Markdown for Agents page).

**Self-hosted (Express / Node)**:
```ts
app.use(async (req, res, next) => {
  // Both variants share a URL; without Vary a cache can serve the markdown to browsers.
  res.vary("Accept");
  const accept = req.headers.accept ?? "";
  const wantsMd = accept.includes("text/markdown") && !accept.includes("text/html");
  if (!wantsMd) return next();

  const md = await renderMarkdownFor(req.path);
  res.setHeader("Content-Type", "text/markdown; charset=utf-8");
  res.send(md);
});
```

Per-route markdown strategy:
- `/` → content of `llms.txt` (or richer home brief)
- `/blog/:slug`, `/docs/:slug` → raw markdown source
- `/projects/:slug` → README + metadata concatenated
- Unknown route → fall back to `llms.txt`

**Audit**:
```bash
curl -sI -H "Accept: text/markdown" https://DOMAIN/ | grep -iE '^(content-type|vary):'
# Expect: text/markdown; charset=utf-8 (not text/html), and Vary including Accept
```

**Skip when**: strictly single-page site (llms.txt alone is sufficient) or authenticated app (agents don't crawl auth).

### 4. Web Bot Auth — `/.well-known/http-message-signatures-directory`

HTTP Message Signatures (RFC 9421) lets your site cryptographically identify *itself* on outbound requests. Publishes a JWKS (JSON Web Key Set) that receivers use to verify signed requests.

**Apply when** your site makes outbound requests (APIs, webhooks, server-to-server) and wants receivers to distinctly whitelist or rate-limit you.

**Skip when** your site only receives traffic. Do not publish an empty placeholder.

**The empty placeholder no longer buys anything.** Earlier versions of this file allowed
`{"keys": []}` for users chasing the scanner score. The scanner's own Web Bot Auth skill now
requires that *"The JWKS must contain at least one public key"*, and a site without a directory
scores `neutral` — *"Web Bot Auth directory not found (informational only)"* — not `fail`
(verified 2026-10-14 — [isitagentready web-bot-auth skill](https://isitagentready.com/.well-known/agent-skills/web-bot-auth/SKILL.md)
and a scan of `https://example.com`; an empty directory itself was not tested). An empty key set
declares a capability the site does not have and signs nothing.

**Full implementation** — what Cloudflare's verifier requires (verified 2026-10-14 —
[Web Bot Auth](https://developers.cloudflare.com/bots/reference/bot-verification/web-bot-auth/),
last updated 2026-10-08):

- Generate an **Ed25519** key pair; Cloudflare ignores other key types. Publish the public JWK(s)
  at `/.well-known/http-message-signatures-directory` with
  **`Content-Type: application/http-message-signatures-directory+json`** — not
  `application/json`.
- **Sign the directory response itself**: one `Signature` / `Signature-Input` pair per key, with
  `tag="http-message-signatures-directory"`, `keyid` set to the key's JWK thumbprint, and
  `@authority` covered with the `req` parameter. The same page lists `req` among the component
  parameters that make verification fail; read that list as applying to the outbound requests
  Cloudflare verifies — `req` only means something in a response signature — but the page does
  not say so (⚠️ unreconciled on the page, 2026-10-14).
- Sign outbound requests per RFC 9421 and send **`Signature-Agent`** naming the directory's
  `https://` origin, listed among the covered components in `Signature-Input`. **A signer that
  follows the WG draft fails on Cloudflare, for two reasons.** The draft says *"Signers MUST send
  the dictionary form"* (`sig1="https://…"`; a verifier *"MAY accept"* the legacy string) and
  covers the header as `"signature-agent";key="sig1"`. Cloudflare says the dictionary form **will
  fail verification**, and its Limitations list the `key` component parameter among those that
  make verification fail (verified 2026-10-14 —
  [draft-ietf-webbotauth-httpsig-protocol-00](https://www.ietf.org/archive/id/draft-ietf-webbotauth-httpsig-protocol-00.txt)
  §5.2.1, Appendix E; Cloudflare page above, "Limitations"). For receivers on Cloudflare, send the
  string form (`Signature-Agent: "https://DOMAIN"`) and cover plain `"signature-agent"` — and say
  that this deviates from the draft's MUST.

**Audit**: `curl -sI https://DOMAIN/.well-known/http-message-signatures-directory | grep -iE '^(content-type|signature|signature-input):'`
→ expect `application/http-message-signatures-directory+json` plus both signature headers, not an
HTML SSR fallback.

## Priority matrix

| Signal | Effort | Risk | Real effect today | Skip if |
|---|---|---|---|---|
| `Link:` response headers | 15 min | Low | Yes — RFC 8288, universally parsed | Never |
| Markdown-for-Agents | 30 min – 2 h | Low–Med | Yes, for agent consumers | Single-page or auth-only site |
| `Content-Signal` in robots.txt | 5 min | 0 | **Almost none** — enforced only by Cloudflare's own `/crawl` API | Fine to skip; add if stating intent matters |
| `Content-Usage` (AIPREF) | 5 min | 0 | **None known** — active draft, no crawler parses it | Fine to skip; add if stating intent matters |
| Web Bot Auth JWKS placeholder | — | — | **None** — signs nothing, and the scanner's check requires a real key and is informational | Always skip |
| Web Bot Auth real signing | 2 h | Low | Yes, for outbound identity | No outbound requests |

**Link headers first.** They are the only item here that is both ratified and actually parsed.
Markdown-for-Agents is a real content-delivery investment. `Content-Signal` and `Content-Usage`
are declarations: cheap, harmless, and nearly inert — ship them if the user wants the scanner green
or wants to state intent, and say which of the two you are doing. Web Bot Auth is real signing or
nothing.

## Standards declaration — Datatracker rows re-verified 2026-10-14, RFC rows 2026-08-14

| Signal | Standing | Source |
|---|---|---|
| **RFC 8288** — Link headers | Stable IETF standard since 2017 | Published RFC |
| **RFC 9421** — HTTP Message Signatures | Stable IETF standard since 2024 | Published RFC |
| **Web Bot Auth** — directory, well-known URI, `Signature-Agent` | WG draft `draft-ietf-webbotauth-httpsig-protocol-00` (2026-09-01, expires 2027-03-05; the draft's header reads *"Intended status: Standards Track"*, while Datatracker records no intended status); Datatracker records it as replacing `draft-meunier-webbotauth-httpsig-protocol`. The two individual drafts Cloudflare's page still cites (`-directory-03`, `-architecture-02`) last reached `-05` and expired 2026-09-03. **No RFC** | [Datatracker](https://datatracker.ietf.org/doc/draft-ietf-webbotauth-httpsig-protocol/) |
| **`Content-Signal`** | Cloudflare convention, **not IETF**; enforced only by Cloudflare's own `/crawl` | See §2 above |
| **`Content-Usage`** (AIPREF) | Both drafts active as of 2026-10-14 — `attach-05` (expires 2027-02-20), `vocab-08` (expires 2027-03-18), intended Proposed Standard; **no RFC published by the WG**, no crawler known to parse it | [Datatracker](https://datatracker.ietf.org/wg/aipref/documents/) |
| **`Accept: text/markdown`** negotiation | Emerging convention, no ratification | — |

Explain this honestly if a user asks. Two of these are standards; the rest are conventions or
drafts — one from a single vendor, two resting on active but unratified drafts, one with no
specification at all. Saying so costs nothing
and is the difference between advice and salesmanship.
