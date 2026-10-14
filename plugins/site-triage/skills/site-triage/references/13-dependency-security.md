# Dependency & supply-chain health

*Loaded by `site-triage` SKILL for repo hardening phase, or when user asks about dep-bot / security / audit / SBOM / license compliance.*

> **Verified 2026-10-14 · review by 2026-12-13.** Claims that can rot carry their own date and
> source inline. A claim without one has not been checked — treat it as unverified, not as fact.
>
> **Not re-read on 2026-10-14**, so still on their 2026-08-14 stamps: Renovate preset names,
> audit/outdated CLI flags, gitleaks CLI modes and the gitleaks-action README notes, the GitHub
> SBOM endpoint and SPDX status, socket.dev and Snyk pricing,
> and rulesets availability. Every version number and SHA was re-resolved on 2026-10-14.

Static/marketing sites still ship third-party code (framework, build tools, wrangler, satori, resvg, font packages). Dependencies rot: CVEs appear, breaking changes land, transitive deps get yanked. Automate this — manual review doesn't scale.

## What to audit in any repo

- `.github/dependabot.yml` or `renovate.json` — automated dep updates. **Exactly one of the two.**
  If the scan finds both live, that is the finding: they open duplicate PRs for the same upgrade and
  each closes the other's. Keep Renovate if the repo already uses grouping, scheduling or a shared
  preset; keep Dependabot otherwise, since it needs no config file to be useful. Removing the loser
  means deleting its config *and* disabling it in repo settings or uninstalling the app — a deleted
  `renovate.json` alone leaves the app running on defaults.
- `.github/workflows/*audit*.yml` — CI audit gate
- GitHub repo Settings → Security and quality → Advanced Security toggles (user confirms in UI)
- A ruleset (or classic branch protection) on `main` — PR + status checks required
- Lockfile committed (pnpm-lock.yaml / yarn.lock / package-lock.json) and used with `--frozen-lockfile` in CI
- Pre-commit hook for secret scanning

## 13.1 Automated dep updates — pick ONE

**Don't run both Dependabot and Renovate on the same repo — duplicate PR flood.**

### Option A: GitHub Dependabot (zero-install, GitHub-native)

`.github/dependabot.yml`:
```yaml
version: 2
updates:
  # npm / pnpm / yarn (auto-detected from lockfile) — check the supported versions note below
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "05:00"
      timezone: "UTC"
    open-pull-requests-limit: 5
    groups:
      minor-patch:
        patterns: ["*"]
        update-types: ["minor", "patch"]
    # Wait out the window where a compromised release is still unnoticed
    cooldown:
      default-days: 7
      semver-major-days: 14
    labels: ["dependencies"]
    commit-message:
      prefix: "chore(deps)"
      include: "scope"

  # GitHub Actions workflow pinning
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule: { interval: "weekly" }
    labels: ["dependencies", "ci"]

  # Docker (if Dockerfile present)
  - package-ecosystem: "docker"
    directory: "/"
    schedule: { interval: "monthly" }
```

> Schema still `version: 2`; every key above is current (verified 2026-10-14 against the
> [Dependabot options reference](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference)).
> Notes from that check:
> - `open-pull-requests-limit` defaults to `5` for version updates — the line above is explicit, not
>   a change in behaviour.
> - `directory` is still valid; `directories` (a list, glob-capable) is the newer plural form.
> - `schedule.interval` accepts `daily`, `weekly`, `monthly`, `quarterly`, `semiannually`, `yearly`,
>   `cron`. `day` / `time` / `timezone` narrow the non-cron intervals.
>
> `cooldown`, re-read 2026-10-14 on the same page:
> - **Dependabot applies a 3-day cooldown to version updates even when `cooldown` is not set.**
>   Security updates are never delayed by it. `default-days` overrides the 3.
> - The page now has a per-ecosystem table. `default-days` works for every listed ecosystem; the
>   `semver-*-days` keys only where marked — **npm and Yarn** (the `npm` ecosystem), Bun, pip,
>   Cargo, Composer, Bundler and other semver ecosystems yes; **GitHub Actions, Docker, Docker
>   Compose, pre-commit**, Helm, Terraform, Git submodules and a few others **`default-days`
>   only**. So the two blocks above without a `cooldown` get the 3-day default, and a
>   `semver-major-days` on the `github-actions` block would do nothing.
> - `include` / `exclude` take up to 150 entries each, wildcards allowed; `exclude` wins.
>
> **Supported package-manager versions** (verified 2026-10-14 —
> [supported ecosystems](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories)):
> npm v7–v11, **pnpm v7–v10**. ⚠️ The pnpm 12 this file pins in §13.3 and npm 12 are both outside
> the documented range. Nothing on the page says what Dependabot does with a newer lockfile; if
> its PRs fail or rewrite `pnpm-lock.yaml` oddly, that gap is the first suspect, and Renovate is the
> alternative to evaluate.

### Option B: Renovate (more configurable, supports automerge)

Install Renovate GitHub App, then `renovate.json`:
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended", ":preserveSemverRanges"],
  "schedule": ["before 5am on monday"],
  "timezone": "UTC",
  "dependencyDashboard": true,
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true,
      "automergeType": "pr",
      "platformAutomerge": true
    },
    {
      "matchPackageNames": ["wrangler"],
      "schedule": ["at any time"],
      "labels": ["wrangler"]
    }
  ],
  "vulnerabilityAlerts": {
    "labels": ["security"],
    "schedule": ["at any time"]
  }
}
```

> `config:recommended` is the current name and `:preserveSemverRanges` still exists (verified
> 2026-08-14 against the [Renovate preset list](https://docs.renovatebot.com/presets-config/)).
> If you are copying from an older guide: `config:base` was the pre-rename name and no longer
> appears in the preset docs — replace it. The `$schema` URL above is the one Renovate publishes,
> so a schema-aware editor will flag a bad key before Renovate ever runs.

## 13.2 GitHub repo-level security toggles (user action)

Enable in `Settings → Security and quality → Advanced Security` (the sidebar section is now
labelled "Security and quality"; an older guide saying `Settings → Security` or
`Settings → Code security` describes the same toggles under a previous label; verified
2026-10-14 against the
[code scanning default setup docs](https://docs.github.com/en/code-security/code-scanning/enabling-code-scanning/configuring-default-setup-for-code-scanning)):

- ✅ **Dependabot alerts** — CVE notifications
- ✅ **Dependabot security updates** — auto-PR on alert
- ✅ **Secret scanning** — runs automatically and free on **public** repos. Organization-owned
  private/internal repos need GitHub Secret Protection on Team or Enterprise Cloud. **A private repo
  on a personal account cannot get it at all** — user-owned repos are covered only on Enterprise
  Cloud with Enterprise Managed Users, or on Enterprise Server (verified 2026-10-14 —
  [about secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning))
- ✅ **Secret scanning push protection** — blocks the push, not the commit, when a supported secret
  is detected — and not only `git push`: it also covers "Commits made in the GitHub UI", "File
  uploads to a repository on GitHub" and "Requests to the REST API". Two distinct things share the name: *push protection for users* is *on by default*
  and stops any user pushing a secret to a **public** repo; *push protection for the repository* is
  **off by default** and must be switched on by an admin/owner (verified 2026-10-14 —
  [about push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection))
- ✅ **Code scanning** (CodeQL default setup) — free where the repo "is publicly visible, or GitHub
  Code Security is enabled"; private repos need the paid license (verified 2026-10-14, same code
  scanning page). Optional; adds CI time
- ✅ **Private vulnerability reporting** — lets researchers file via `security/advisories`

⚠️ Every free/paid line here is licensing, which GitHub renames and re-tiers more often than it
changes behaviour ("Advanced Security" has already split into Code Security and Secret Protection).
Confirm in the repo's own settings page before promising a user something is free.

## 13.3 CI audit gate

`.github/workflows/audit.yml`:
```yaml
name: Audit dependencies

on:
  pull_request:
    paths:
      - "package.json"
      - "pnpm-lock.yaml"
      - "yarn.lock"
      - "package-lock.json"
  schedule:
    - cron: "0 5 * * 1"   # weekly Mon 05:00 UTC
  workflow_dispatch:

permissions: { contents: read }

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1  # v7.0.1
      - uses: pnpm/action-setup@ea17c68df8912ef543352723c149a84f56e3d413  # v6.1.0
        with: { version: 12 }
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1  # v7.1.0
        with: { node-version: 24, cache: "pnpm" }
      - run: pnpm install --frozen-lockfile
      - run: pnpm audit --audit-level=moderate
      - run: pnpm outdated --long || true

  secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1  # v7.0.1
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@e0c47f4f8be36e29cdc102c57e68cb5cbf0e8d1e  # v3.0.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          # Organization-owned repos only; personal accounts leave this unset
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}
```

Every version in that workflow was checked on 2026-10-14 via
`gh api repos/<owner>/<repo>/releases/latest`, and every action — first-party included — is
SHA-pinned per §13.7. What changed since the previous major-version generation of this example:

| Action | Was | Now | Latest release |
|---|---|---|---|
| `actions/checkout` | v4 | **v7** | `v7.0.1`, 2026-07-20 |
| `actions/setup-node` | v4 | **v7** | `v7.1.0`, 2026-10-08 |
| `pnpm/action-setup` | v4 | **v6** | `v6.1.0`, 2026-09-05 — adds pnpm 12 support. ⚠️ The floating `v6` tag still points at `v6.0.10` (`0977fd99…`, re-checked 2026-10-14), so pin the `v6.1.0` SHA, not `@v6`, for pnpm 12 |
| `gitleaks/gitleaks-action` | v2 | **v3** | `v3.0.0`, 2026-05-30 |
| `github/codeql-action` | v3 | **v4** | tag `v4.38.3` (2026-10-08) |

Four things that bite when copying an older version of this file:

- **`node-version: 20` is end-of-life.** Node 20 (Iron) went EOL 2026-04-30; Node 22 (Jod) is in
  maintenance until 2027-04-30. **Node 24 (Krypton)** is active LTS until 2026-10-20, then in
  maintenance until 2028-04-30; **Node 26** becomes active LTS on 2026-10-28 (verified 2026-10-14
  against the [Node release schedule](https://github.com/nodejs/Release/blob/main/schedule.json)).
  Either 24 or 26 is a correct `node-version:` from late October 2026 on, and there is no rush to
  move an existing 24 pin — read `schedule.json` rather than trusting the number in the example.
- **This is a different "Node 20" from the runner one.** GitHub-hosted runners stopped offering
  Node 20 *to run JavaScript actions* on 2026-09-23: actions declaring `runs.using: node20` now run
  on Node 24 and the `ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION` opt-out is gone (verified
  2026-10-14 — [GitHub changelog](https://github.blog/changelog/2026-09-23-node-20-is-no-longer-available-in-github-actions/)).
  An old pinned action version may misbehave on that; `node-version:` above is the separate question of
  which Node your *project* builds with.
- **`pnpm/action-setup` needs `version:`** unless `package.json` declares `packageManager` (or
  `devEngines.packageManager`). The old example omitted it and silently depended on that field
  existing. **pnpm 12 is `latest`** (`12.11.2`; `latest-11` is `11.28.2`, `latest-10` is
  `10.34.6`; `npm view pnpm dist-tags`, 2026-10-14), so the example pins `version: 12`. The
  action's README reads *"This action supports pnpm v12 and earlier"* and says it can stay paired
  with `actions/setup-node` for v11 and v12 (re-read 2026-10-14). Remember Dependabot documents
  pnpm only up to v10 (§13.1). The alternative, [`pnpm/setup`](https://github.com/pnpm/setup), is
  at **`v3.1.1`** (2026-10-10). It installs the standalone pnpm binary plus a runtime in one step,
  replacing `actions/setup-node`, and supports **pnpm v11 and newer only**; its README adds that
  pnpm v11 publishes no Intel macOS binary, so use v12 there:
  ```yaml
  - uses: pnpm/setup@a0881977cd8ea73b1ed212236c99ca10dcc80cf4  # v3.1.1
    with: { version: 12, runtime: node@24, cache: true }
  ```
  `v3` also runs `pnpm install` by default when a `package.json` is present — set
  `install: false` for a job that only audits (both inputs present in the `v3.1.1` `action.yml`).
  Pick one of the two actions per job.
- **gitleaks-action v3 wants `GITLEAKS_LICENSE` for organization repos**, not personal accounts —
  that is a v2-era condition that still holds, and a missing license is the usual reason the job
  fails on an org repo. v3 is otherwise a drop-in: same inputs and outputs, only the Actions runtime
  moved from Node 20 to Node 24 (verified 2026-08-14 against the
  [gitleaks-action README](https://github.com/gitleaks/gitleaks-action)).

Package manager equivalents (flags verified 2026-08-14 against each tool's own CLI docs):
| Manager | Audit | Outdated |
|---|---|---|
| pnpm | `pnpm audit --audit-level=moderate` | `pnpm outdated --long` |
| yarn (berry) | `yarn npm audit --severity moderate --recursive` | ⚠️ no `yarn outdated` — see below |
| npm | `npm audit --audit-level=moderate` | `npm outdated` |

- `--audit-level` accepts `info` `low` `moderate` `high` `critical` `none` on npm
  ([npm-audit](https://docs.npmjs.com/cli/v11/commands/npm-audit)); pnpm accepts `low` `moderate`
  `high` `critical`, defaulting to `low` ([pnpm audit](https://pnpm.io/cli/audit)). `moderate` is
  valid on both.
- **`yarn outdated` does not exist in modern Yarn.** It was a Yarn 1 command and is absent from the
  Yarn Berry command list — the old table entry would fail with an unknown-command error. The
  built-in equivalent is `yarn upgrade-interactive` (interactive, not CI-friendly); for a
  non-interactive check, run `npm outdated` against the same `package.json`. Yarn's audit flag is
  `--severity` (`info`/`low`/`moderate`/`high`/`critical`), not `--audit-level`
  ([yarn npm audit](https://yarnpkg.com/cli/npm/audit)). Note the npm `yarn` package is still
  `1.22.22` (2024-03-09) — that is the Yarn 1 shim, not a sign Berry is unmaintained.

## 13.4 Secret scanning — pre-commit + CI

CI: already in §13.3 (Gitleaks).

Pre-commit via husky:
```bash
pnpm add -D husky
pnpm exec husky init
echo 'gitleaks git --pre-commit --staged --verbose' >> .husky/pre-commit
```

> `gitleaks protect` was deprecated in v8.19.0 — still present but hidden from `--help`. Current
> modes are `git`, `dir`, `stdin`. Verified 2026-08-14 against the
> [gitleaks README](https://github.com/gitleaks/gitleaks). Note gitleaks is a Go binary, not an npm
> package: `npx gitleaks` does not install it. Use Homebrew, the release binary, or the Docker image.

Or via `pre-commit` framework in `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.30.1
    hooks: [{ id: gitleaks }]
```

> `rev: v8.18.0` was two years of releases behind — gitleaks latest is `v8.30.1`, published
> 2026-03-21 (verified 2026-10-14 via `gh api repos/gitleaks/gitleaks/releases/latest`). A stale
> `rev` here is not cosmetic: the rule set that detects new provider token formats ships with the
> binary. Pin a real tag and let Dependabot's `pre-commit` ecosystem or `pre-commit autoupdate`
> move it.

**If a secret was committed — order of operations**:
1. **Rotate the credential** at the provider (revoke, regenerate) FIRST
2. Then scrub history: `git filter-repo --path <file> --invert-paths` (or BFG Repo Cleaner).
   `git-filter-repo` is a separate install (`brew install git-filter-repo`), not a built-in git
   subcommand; latest release `v2.47.0`, 2024-12-04 — quiet, not abandoned (verified 2026-10-14)
3. `git push --force-with-lease` with team coordination
4. Invalidate any deploys that used the old secret

Never just `git rm` the file — old commits retain it forever in the object store.

## 13.5 License compliance

Catch incompatible licenses (GPL polluting MIT is the classic footgun):
```bash
pnpm licenses list                                    # pnpm native, no extra dependency
npx license-checker-rseidelsohn --summary             # maintained fork
npx license-checker-rseidelsohn --failOn 'GPL-3.0;AGPL-3.0;SSPL-1.0'
```

> Do not use `license-checker`: latest is `25.0.1`, published 2019-01-10 — unmaintained for over
> seven years. The fork `license-checker-rseidelsohn` is at `5.0.1` (2026-05-27) and is the drop-in
> replacement. Both verified 2026-10-14 against the npm registry. Prefer the package manager's own
> command where one exists — that is the dependency you already have.

Add as CI step if project has license policy.

## 13.6 SBOM (Software Bill of Materials)

Some enterprise customers require. US EO 14028 pushed adoption:
```bash
# CycloneDX (industry standard) — npm package, npx works
npx @cyclonedx/cyclonedx-npm --output-file sbom.cdx.json

# SPDX (Linux Foundation standard) — Syft is a Go binary, install it first
brew install syft            # or: curl -sSfL https://get.anchore.io/syft | sh -s -- -b /usr/local/bin
syft dir:. -o spdx-json > sbom.spdx.json
```

> **`npx @anchore/syft` does not work — there is no such npm package** (registry returns 404,
> verified 2026-10-14). `@cyclonedx/cyclonedx-npm` is real and current: `6.0.1`, published
> 2026-08-11 (same check). If only one SBOM format is needed, CycloneDX is the one with no
> extra install step. Syft latest is `v1.54.1`, 2026-10-06 (re-checked 2026-10-14; `6.0.1` also
> still current on that date).

Third option, zero install, if the repo is on GitHub with the dependency graph enabled — GitHub
generates an SPDX SBOM itself:
```bash
gh api repos/OWNER/REPO/dependency-graph/sbom > sbom.spdx.json
```
Verified working 2026-08-14 (returns an SPDX document; the endpoint emitted `SPDX-2.3` on the
repo tested). Free on public repos, and it needs no local toolchain — but it describes what the
dependency graph knows, not what a build actually produced, so it is the weaker artifact of the
three for attestation purposes.

Format status, verified 2026-08-14 via each specification's own releases:
- **CycloneDX** specification `1.7.2`, 2026-09-17 (re-checked 2026-10-14) — still actively
  versioned. Check which spec version your generator emits; a tool can be current while
  defaulting to an older spec.
- **SPDX** specification `3.0.1`, 2024-12-17. ⚠️ Most tooling still emits SPDX **2.3** by default
  (Syft's `spdx-json` output and the GitHub endpoint above both did on the check date). If a
  customer contract names SPDX 3.x specifically, verify the emitted `spdxVersion` field rather
  than assuming.

Attach to GitHub Release artifacts.

## 13.7 Supply-chain hardening

- **npm provenance** — `npm publish --provenance` attests the package was built from the claimed
  source repo at the claimed commit (Sigstore-backed, free). Still the documented flag, with two
  conditions worth knowing (verified 2026-10-14 —
  [generating provenance statements](https://docs.npmjs.com/generating-provenance-statements), last edited 2026-05-04):
  the build must run on a cloud-hosted runner of a supported provider — **GitHub Actions or GitLab
  CI/CD, those two only** — and `package.json` must point at a public `repository`. **Trusted
  publishing** from those same two providers generates provenance automatically: "When you publish
  using trusted publishing from GitHub Actions or GitLab CI/CD, npm automatically generates and
  publishes provenance attestations", no `--provenance` flag needed. Not from CircleCI, and not
  from a private repository even when the package is public (verified 2026-10-14 —
  [trusted publishers](https://docs.npmjs.com/trusted-publishers), last edited 2026-10-06).
  Trusted publishing is the better path either way, since it removes the long-lived npm token
  from CI. Consumers verify with `npm audit signatures`.
- **npm trusted publishing** (verified 2026-10-14 —
  [trusted publishers](https://docs.npmjs.com/trusted-publishers), page last edited 2026-10-06):
  supported on GitHub Actions (GitHub-hosted runners), GitLab CI/CD (GitLab.com shared runners) and,
  since 2026-04-06, CircleCI cloud
  ([changelog](https://github.blog/changelog/2026-04-06-npm-trusted-publishing-now-supports-circleci/));
  self-hosted runners are not. Two changes from 2026-10-02
  ([changelog](https://github.blog/changelog/2026-10-02-unvalidated-npm-trusted-publishing-configurations-now-expire/)):
  a new trusted-publisher configuration **expires unless its first publish succeeds within 48
  hours** (the docs say "2 days") — create it right before the release, not weeks ahead; and npm
  now **rejects tokens from `issue_comment` workflows**, alongside the existing
  `pull_request_target` restriction — publish from `push`, `release` or `workflow_dispatch`. A
  CircleCI publish carries no provenance: "Provenance generation is not currently supported for
  CircleCI" (same page).
- **Lockfile discipline** — always commit, always `--frozen-lockfile` / `--immutable` in CI (fails if lockfile drifts)
- **Release-age gates and install scripts** — every major package manager can now refuse versions
  younger than a set age, which is the cheapest defence against a compromised release that gets
  pulled within hours. The units differ, and that is where copied configs go wrong (all verified
  2026-10-14 against each tool's own docs or source):

  | Manager | Setting | Unit | Default |
  |---|---|---|---|
  | npm | `min-release-age` (`.npmrc`) | **days** | off (`null`) — [npm config](https://docs.npmjs.com/cli/v12/using-npm/config) |
  | pnpm | `minimumReleaseAge` (`pnpm-workspace.yaml`) | **minutes** | **`1440` (1 day) since v11**, `0` before; added in 10.16.0 — [pnpm settings](https://pnpm.io/settings/dependency-resolution#minimumreleaseage) |
  | Bun | `install.minimumReleaseAge` (`bunfig.toml`) | **seconds** | off (`null`) — [bunfig](https://bun.com/docs/runtime/bunfig) |
  | Yarn (Berry) | `npmMinimalAgeGate` (`.yarnrc.yml`) | duration string (`1d`, `3h`, `1w`; bare number = minutes) | **`1d` since 4.15.0** (2026-05-19), `0m` in 4.11.0–4.14.1; added in 4.10.0 as a plain minute count, default `0` — `packages/plugin-npm/sources/index.ts` at each `@yarnpkg/cli/<version>` tag, [yarnrc](https://yarnpkg.com/configuration/yarnrc) |

  A week is `min-release-age=7` on npm, `minimumReleaseAge: 10080` on pnpm,
  `minimumReleaseAge = 604800` on Bun and `npmMinimalAgeGate: "1w"` on Yarn. Dependabot's
  `cooldown` (§13.1) is the same idea applied to the PRs, not the install. pnpm also has
  `trustPolicy: no-downgrade` (default off, since 10.21.0): install fails if a version carries
  weaker trust evidence — say, no provenance where earlier releases were trusted-published — than
  versions published before it.

  Install scripts: **npm 12 blocks dependency lifecycle scripts by default** unless the root
  `package.json`'s `allowScripts` policy allows them (`npm install-scripts approve`, then
  `npm rebuild`), and `allow-git` / `allow-remote` now default to `none`, so git and tarball-URL
  dependencies need an explicit opt-in (verified 2026-10-14 —
  [npm v12.0.0 release notes](https://github.com/npm/cli/releases/tag/v12.0.0), 2026-07-08; npm
  `latest` is `12.2.0`). pnpm has blocked dependency `postinstall` scripts since v10, with
  `allowBuilds` as the allowlist ([pnpm supply-chain security](https://pnpm.io/supply-chain-security)).
  An upgrade to npm 12 that "breaks" a native dependency is usually this, not a bug.
- **Lock or SHA-pin every Action — first-party included.** GitHub's secure-use reference now puts a
  **workflow dependency lockfile** first: it "supersedes SHA pinning for repositories that adopt
  it". Without one, pin every action to a full-length commit SHA, and pin to a tag "only if you
  trust the creator", with the caveat that "a tag can be moved or deleted" — there is no carve-out
  for GitHub's own actions. The repository setting **Require actions to be pinned to a full-length
  commit SHA** explicitly "includes … actions authored by GitHub" (all verified 2026-10-14 —
  [secure use reference](https://docs.github.com/en/actions/reference/security/secure-use),
  [repository Actions settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository)).
  ```yaml
  steps:
    # Good — SHA, with the tag it resolved to in a trailing comment
    - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1  # v7.0.1
    # Risky — any owner, GitHub included
    - uses: actions/checkout@v7
    - uses: some-user/some-action@v1
  ```
  One trade-off the same page states: Dependabot "will not create alerts for actions pinned to SHA
  values". It still opens version-update PRs for them — the `github-actions` updater supports the
  `actions/checkout@<commit>` form, and a commit "not associated with any tag" is moved to the
  latest commit rather than the latest release (verified 2026-10-14 —
  [supported ecosystems](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories#github-actions)) —
  so keep the `github-actions` ecosystem in `dependabot.yml`.

  **Workflow lockfile — public preview**, "subject to change": `.github/workflows/actions.lock`,
  generated by the `gh actions-lock` CLI extension and never hand-edited. It records the commit
  *and* the numeric owner/repo IDs of every action and reusable workflow, and extends to transitive
  dependencies "**except** for dependencies of reusable workflow calls" — those are covered by the
  lockfile of the repository that defines the reusable workflow. Workflows are onboarded "one at a
  time or all at once"; the lockfile's `workflows:` section lists which ones are in, and once a
  workflow is onboarded every action it uses must be in the lock. Locked dependencies satisfy the
  SHA-pinning setting without SHAs in the workflow file, but "Dependencies that aren't in the
  lockfile still need a full-length SHA" (verified 2026-10-14 —
  [workflow dependency lockfiles](https://docs.github.com/en/actions/concepts/security/workflow-dependency-lockfiles),
  [repository Actions settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository)).
  Dependabot regenerates the lock entry in the same PR when it bumps an action in an onboarded
  workflow, but "will **not** onboard a workflow for you" (verified 2026-10-14 —
  [lock workflow dependencies](https://docs.github.com/en/actions/how-tos/secure-your-work/lock-workflow-dependencies)).
  Because it is a preview, SHA pins remain this file's default. Workflows onboarded to an
  `actions.lock` are covered and should not be flagged for tag references; every other workflow in
  the same repo still is (§13.11 check 4 makes that split).

  > The SHA previously given here (`b4ffde65…`) still resolves — but to a commit from **2023-10-17**,
  > i.e. the `actions/checkout` v4 line, four majors behind. That is the failure mode of pinning
  > without a bot: it keeps working and quietly stops being maintained. The SHAs above and below
  > were re-resolved 2026-10-14; re-resolve rather than copying them, and let Dependabot's
  > `github-actions` ecosystem move the pins. It rewrites the SHA, and "updates the version
  > documentation of GitHub Actions when the comment is on the same line", e.g.
  > `actions/checkout@<commit> #<tag or link>` (verified 2026-10-14 — same supported-ecosystems page).
  >
  > **Dereference annotated tags or the pin is wrong.** `gh api repos/<owner>/<repo>/git/ref/tags/<tag>`
  > returns `.object.type == "tag"` for an annotated tag, and its `.object.sha` is the *tag object*,
  > not a commit — pinning it does not resolve. Two rows of this table were wrong for exactly that
  > reason until 2026-08-28. Resolve in one step instead:
  >
  > ```bash
  > gh api repos/<owner>/<repo>/commits/<tag> --jq .sha    # follows tag -> commit for both kinds
  > ```
  >
  > And do not take the tag from `releases/latest` blindly: for `github/codeql-action` it returns a
  > `codeql-bundle-v…` release, not the `v4.x` action tag — list releases and pick the `v4` line.
  >
  > | Action | Tag | Commit SHA on 2026-10-14 |
  > |---|---|---|
  > | `actions/checkout` | v7.0.1 (= `v7`) | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
  > | `actions/setup-node` | v7.1.0 (= `v7`) | `949feb2413d6458794dcd2491c4babbbce0c15c1` |
  > | `github/codeql-action` | v4.38.3 (= `v4`) | `24c54180a607b1449ed407dd24f251e4e9147c8d` |
  > | `pnpm/action-setup` | v6.1.0 | `ea17c68df8912ef543352723c149a84f56e3d413` |
  > | `pnpm/setup` | v3.1.1 (= `v3`) | `a0881977cd8ea73b1ed212236c99ca10dcc80cf4` |
  > | `gitleaks/gitleaks-action` | v3.0.0 (= `v3`) | `e0c47f4f8be36e29cdc102c57e68cb5cbf0e8d1e` |
  > | `cloudflare/wrangler-action` | v4.1.3 (= `v4`) | `953926a2e2182532811c01a25e53647d93bf07c0` |

- **socket.dev** — GitHub App reviews dep-change PRs for supply-chain red flags (install scripts,
  shell exec, network calls, typosquat). Zero config, high signal. ⚠️ "Free for public repos" was
  imprecise: the published Free plan is metered, not repo-visibility-scoped — unlimited repos and
  developers but **1,000 scans/month, 3 team members**, and open-source projects are told to ask
  for a complimentary Team account (read from [socket.dev/pricing](https://socket.dev/pricing) on
  2026-08-14; vendor pricing is the fastest-rotting claim in this file — re-read the page before
  quoting a number to anyone).
- **Production install** — CI deploys with `pnpm install --prod` (skip devDeps, reduce attack surface)

## 13.8 Branch protection baseline

Two mechanisms exist. **Rulesets** (`Settings → Rules → Rulesets`) are the newer one; classic
branch protection (`Settings → Branches`) still works. GitHub's own docs stop short of calling
classic rules deprecated — the wording is that the two "work alongside each other, and all
applicable rules are enforced" — but rulesets are what the docs describe as offering "more
flexible ways to manage and understand protections": several can apply at once, each has an
enforcement status (including evaluate/dry-run), and anyone with read access can see them
(verified 2026-08-14 — [about rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)).
**Prefer a ruleset for a new repo**; don't rewrite a working classic rule just to migrate.

⚠️ Availability differs from classic protection: rulesets are available on **public** repos under
GitHub Free, and on public *and private* repos under Pro/Team/Enterprise Cloud. A private repo on
a free plan cannot use them. Limit is 75 rulesets per repo.

Whichever mechanism, the baseline is the same:
- ☑ Require PR before merging
- ☑ Require status checks: audit, lint, build, test
- ☑ Require branches up to date
- ☑ Require conversation resolution
- ☑ Require signed commits (optional; GPG or SSH signing)
- ☑ Restrict who can push (include admins if strict)
- ☑ Block force pushes

Both REST endpoints answered on 2026-08-14, so `gh` drives either one:
```bash
# Rulesets — read what is already there, then inspect one
gh api repos/OWNER/REPO/rulesets
gh api repos/OWNER/REPO/rulesets/RULESET_ID

# Classic branch protection — read (404 simply means "no protection set")
gh api repos/OWNER/REPO/branches/main/protection
```

Writing either config from the CLI means a `PUT`/`POST` with a full JSON body — there is no
`gh` shorthand flag for it, and a partial body **replaces** the existing settings rather than
merging. For an audit, read with the commands above and let the user apply changes in the UI;
that matches the plugin's propose-then-approve rule.

Solo maintainers can relax to "status checks only"; still use PRs for big changes.

## 13.9 Scanner tool matrix

⚠️ **The "free tier" column is the least durable thing in this file.** Vendors re-tier quietly and
none of them announce it in a changelog you can diff. Every row was read from the vendor's own
pricing or docs page on 2026-08-14; treat anything below as needing a re-read before it is quoted
to a user as a commitment.

| Tool | Free tier (checked 2026-08-14) | Scope | Delivery | Alive? |
|---|---|---|---|---|
| Dependabot | ✅ all repos | CVE alerts + auto-PR | GitHub native | current |
| Renovate | ✅ all repos | Deeper config + more ecosystems | GitHub App | current |
| `pnpm/yarn/npm audit` | ✅ | Node CVEs | CLI + CI | current |
| socket.dev | ⚠️ metered: 1,000 scans/mo, 3 members, unlimited repos; OSS can request a free Team account | Supply chain / malicious detection | GitHub App | current |
| Snyk | ⚠️ per-product monthly test counts, not one pool: **200** Open Source (SCA), **100** Code (SAST), **100** Container, **300** IaC | CVE + license + IaC | GitHub App + CLI | current |
| CodeQL | ✅ public repos; private needs paid Code Security | Static analysis | GitHub Actions | `codeql-action` `v4.38.3`, 2026-10-08 |
| Gitleaks | ✅ CLI; ⚠️ the **Action** needs `GITLEAKS_LICENSE` on org-owned repos | Secret scan | Pre-commit + CI | CLI `v8.30.1`, 2026-03-21 |
| TruffleHog | ✅ open source | Secret scan (deeper entropy) | Pre-commit + CI | `v3.99.2`, 2026-10-08 |
| license-checker-rseidelsohn | ✅ | License audit | CLI + CI | `5.0.1`, 2026-05-27 |
| CycloneDX / Syft | ✅ | SBOM | CLI + release | `6.0.1` (2026-08-11) / `v1.54.1` (2026-10-06) |

The old table said Snyk gave "200 tests/mo" flat — that number is only the Open Source product's
allowance ([snyk.io/plans](https://snyk.io/plans/), read 2026-08-14). Release dates in the last
column come from `gh api repos/<owner>/<repo>/releases/latest` and the npm registry, re-run
2026-10-14; all four scanners are actively released, none are abandoned.

## 13.10 Day-1 baseline for any public repo

Ship these together on repo creation or first audit pass. ~30 min total, then autopilot:

1. `.github/dependabot.yml` — weekly grouped npm + actions + docker updates, with a `cooldown`
2. GitHub Settings → Security and quality → Advanced Security: alerts + security updates + secret
   scanning + push protection (remember repository-level push protection is off by default) all ✓
3. `.github/workflows/audit.yml` — audit + outdated + Gitleaks on PR + weekly cron
4. Pre-commit hook: Gitleaks staged scan
5. Ruleset (or classic branch protection) on main: PR + status checks required
6. Lockfile committed; CI uses `--frozen-lockfile`
7. Every GitHub Action pinned to a full commit SHA — first-party included — or covered by a
   workflow lockfile (`.github/workflows/actions.lock`, public preview); see §13.7
8. (Optional) socket.dev GitHub App installed

## 13.11 Mode B rapid checklist

```bash
# 1. Dep-bot?
ls .github/dependabot.yml renovate.json 2>/dev/null

# 2. CI audit workflow? (-rl also catches .yaml, and survives zero matches)
grep -rlE "(audit|snyk|gitleaks|trufflehog)" .github/workflows/ 2>/dev/null || echo "MISSING: no audit workflow"

# 3. Lockfile committed?
ls pnpm-lock.yaml yarn.lock package-lock.json 2>/dev/null

# 4. Actions not SHA-pinned — one line per offender, then a one-line verdict. First-party actions/*
# and github/* count too. Workflows listed under `workflows:` in actions.lock are covered by the
# lockfile and skipped; every other workflow file still needs full-length SHAs (§13.7).
lock=.github/workflows/actions.lock
onboarded=$([ -f "$lock" ] && tr -d '\r' < "$lock" | sed -n '/^workflows:/,/^dependencies:/p' \
  | grep -oE '\.github/workflows/[A-Za-z0-9._/-]+\.ya?ml')
scanned=0; locked=0; bad=""
for f in $(find .github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | sort); do
  if printf '%s\n' "$onboarded" | grep -qxF "$f"; then locked=$((locked+1)); continue; fi
  scanned=$((scanned+1))
  hits=$(tr -d '\r' < "$f" | grep -E "^[[:space:]-]*\{?[[:space:]]*uses:" \
    | grep -oE "uses:[[:space:]]+['\"]?[^[:space:]'\"#},]+" | sed -E "s/uses:[[:space:]]+['\"]?/uses: /" \
    | grep -vE '@[0-9a-f]{40}$' | grep -vE 'uses: (\./|\$/|docker://)' | sort -u | sed "s|^|$f: |")
  [ -n "$hits" ] && bad="$bad$hits
"
done
if [ -n "$bad" ]; then
  printf '%s' "$bad"; echo "FAIL: $(printf '%s' "$bad" | grep -c .) unpinned action ref(s) above"
else
  echo "OK: $scanned workflow file(s) SHA-pinned, $locked covered by actions.lock"
fi

# 5-7. Run the ONE package manager the project uses. `a || b` is wrong here: these tools exit
# non-zero when they FIND something, so the fallback fires on a real vulnerability and runs the
# second tool against a lockfile it cannot read.
if [ -f pnpm-lock.yaml ]; then
  pnpm audit --audit-level=moderate; pnpm outdated --long; pnpm licenses list
elif [ -f yarn.lock ]; then
  yarn npm audit --severity moderate; npm outdated   # Berry has no `yarn outdated` — see §13.3
elif [ -f bun.lock ] || [ -f bun.lockb ]; then
  bun audit; bun outdated
else
  npm audit --audit-level=moderate; npm outdated
fi
npx license-checker-rseidelsohn --summary 2>/dev/null || true   # any manager, if the above has no licences command

# 8. Agent-ready signals (see 06-agent-ready.md)
curl -sI "https://DOMAIN/" | grep -iE "^link:" || echo "MISSING: Link headers"
curl -sI -H "Accept: text/markdown" "https://DOMAIN/" | grep -i "^content-type: text/markdown" || echo "MISSING: Markdown-for-Agents"
# Web Bot Auth: a 404 is correct unless the site operates a bot that signs its outbound requests
# (06-agent-ready.md §4). Set SIGNS_REQUESTS=yes only for such a site.
SIGNS_REQUESTS=no
if [ "$SIGNS_REQUESTS" = yes ]; then
  curl -sI --max-time 10 "https://DOMAIN/.well-known/http-message-signatures-directory" | grep -i "^content-type: application/http-message-signatures-directory+json" || echo "MISSING: Web Bot Auth key directory (site signs requests)"
else
  echo "INFO: Web Bot Auth not checked — no signing bot, so no key directory is expected"
fi
```

> Check 4 was rewritten on 2026-08-14 because the previous regex — `uses: [^a-zA-Z].*@v[0-9]` —
> **matched nothing on any real workflow**: it required a non-letter immediately after `uses: `,
> while every action reference starts with an owner name. Confirmed by running it against a
> fixture containing two deliberately unpinned third-party actions; it exited 1 and printed
> nothing, i.e. it reported "all pinned" for a repo that was not. On 2026-10-14 it changed again:
> it no longer exempts first-party `actions/*` and `github/*` (GitHub's own guidance has no such
> carve-out, §13.7), it catches branch refs such as `@main` as well as `@v…` tags, and it skips local
> `./` actions and `docker://` images. Later the same day it was rewritten a third time, after a
> review showed the lockfile branch printed `OK` and skipped every file whenever `actions.lock`
> existed — a fixture with one onboarded workflow and an un-onboarded `release.yml` using a
> tag-pinned third-party action passed. GitHub onboards workflows "one at a time or all at once",
> and "Dependencies that aren't in the lockfile still need a full-length SHA" (verified 2026-10-14 —
> [workflow dependency lockfiles](https://docs.github.com/en/actions/concepts/security/workflow-dependency-lockfiles),
> [repository Actions settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository)).
> The check now reads the onboarded paths from the lockfile's `workflows:` section (the format on
> the first page) and greps every other `.yml`/`.yaml` file. It also tolerates several spaces after
> `uses:`, quoted refs, flow-style `{ uses: … }` steps and CRLF files, ignores commented-out lines,
> and skips `$/…` references, which `gh actions-lock` writes for in-repo actions and which are
> "inherently pinned" ([lock workflow dependencies](https://docs.github.com/en/actions/how-tos/secure-your-work/lock-workflow-dependencies)).
> Tested on 2026-10-14 under sh, bash and zsh against fixtures covering each of those cases, a
> repo with no lockfile, and one with no workflows (the file list comes from `find`, not a glob,
> because zsh aborts on a glob that matches nothing). If a future lockfile format stops matching, nothing counts as onboarded and
> every workflow is grepped — noisy, never silently clean. A cross-repository reusable workflow
> (`owner/repo/.github/workflows/x.yml@v2`) is listed too; the SHA-pinning setting still accepts
> those by tag ("Reusable workflows can still be referenced by tag", same settings page), so treat
> that line as a judgement call rather than a policy violation. The last line is the verdict:
> `OK: …` or `FAIL: N unpinned action ref(s) above`.

Roll output into severity gap report:
- 🔴 **Critical**: active CVE, secret detected, no branch protection
- 🟡 **Recommended**: no Dependabot/Renovate, no CI audit gate, actions not SHA-pinned (outside workflows onboarded to `actions.lock`), license violation, no `Link:` headers, no Web Bot Auth key directory on a site that operates a signing bot
- 🟢 **Nice**: no SBOM, no socket.dev, no pre-commit secret scan, no Markdown-for-Agents
- ⚪ **Intent only**: no `Content-Signal` — no known technical effect (`06-agent-ready.md`)
