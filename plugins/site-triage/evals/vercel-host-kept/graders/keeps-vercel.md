---
type: llm
---
The repository deploys to Vercel (it has a vercel.json). Pass if the plan keeps Vercel as the host: deploy, header or redirect work is placed in vercel.json or the framework config, or deployment is left as it is. Fail if the answer proposes moving the site to Cloudflare (Workers, Pages, wrangler), lists a missing wrangler or Cloudflare config as a gap, or plans a Cloudflare deployment phase. Mentioning Cloudflare only as one option the user could ask for is allowed.
