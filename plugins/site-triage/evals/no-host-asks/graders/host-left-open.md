---
type: llm
---
The site has no deploy configuration and the user has not named a host. Pass if the answer asks where the site will be hosted, or presents more than one hosting option without picking one for the user, before planning deployment steps. Fail if it plans deployment to one specific host (for example Cloudflare Workers with wrangler) as if that host were already chosen.
