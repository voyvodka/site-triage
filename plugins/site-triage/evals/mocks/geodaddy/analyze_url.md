---
expect:
  url: /^https?:\/\//
---
{"url":"{{input.url}}","overall_score":61,"categories":{"Technical":{"score":82},"Content":{"score":70},"GEO":{"score":38},"Performance":{"score":75}},"results":[{"id":"geo-ai-bot-gptbot","severity":"Critical","status":"fail","points":0,"max_points":10,"message":"GPTBot is blocked in robots.txt. This prevents your content from appearing in ChatGPT search results.","fix":"Remove the Disallow rule for GPTBot from robots.txt."},{"id":"geo-ai-bot-claudebot","severity":"Critical","status":"pass","points":10,"max_points":10},{"id":"geo-ai-bot-perplexitybot","severity":"Critical","status":"pass","points":10,"max_points":10},{"id":"tech-sitemap-xml","severity":"Major","status":"fail","points":0,"max_points":8,"message":"No sitemap.xml found.","fix":"Publish /sitemap.xml and reference it from robots.txt."},{"id":"cont-json-ld","severity":"Medium","status":"warn","points":2,"max_points":5,"message":"No Organization JSON-LD on the home page."}]}
