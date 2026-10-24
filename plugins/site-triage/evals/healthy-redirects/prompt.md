---
tags: [rules]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 8
---
My docs site has 40 pages, all indexed. Search Console also lists 39 URLs under "Page with redirect". I checked them: every one is the slashless version of a real page, for example /guide/install, and each answers a single 308 to /guide/install/, which returns 200 and is canonical. The sitemap only lists the slash versions. Should I fix these 39?
