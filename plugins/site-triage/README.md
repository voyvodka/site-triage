# site-triage

Works out why a live site is not showing up in Google, traces each reason to the file or setting
that causes it, fixes it, and verifies the fix. It also covers the launch side: discoverability
files, Cloudflare Workers deployment, and repository hardening.

## Install

Install it from the marketplace that lists it; the `repository` URL in
`.claude-plugin/plugin.json` leads to the repository README, which has the exact commands and the
Claude Code versions they need.

## Usage

```
/site-triage
```

Run it in a site's repository. It picks a mode — launch, audit, or brand-only — scans the project,
and reports a severity-ranked list before changing anything. It also loads when you ask about
indexing, Search Console, GEO, or a Cloudflare deployment.

## What is in this folder

```
plugins/site-triage/
├── .claude-plugin/plugin.json   manifest
├── .mcp.json                    the GeoDaddy MCP server, fetched with npx on first use
├── evals/                       behaviour cases for `claude plugin eval`; see evals/README.md
└── skills/site-triage/
    ├── SKILL.md                 modes, scan phase, capability index
    └── references/              one file per capability, loaded on demand
```

## Requirements

`curl`, `grep` and a POSIX shell for the diagnostic checks. GeoDaddy and Search Console access are
optional. The manifest's `network.hosts` lists the hosts the GeoDaddy server is fetched from; the
checks and `analyze_url` also reach whichever site you ask about, which no list can name ahead of
time.

Limits, the reasoning behind them, and troubleshooting are in the repository README.
