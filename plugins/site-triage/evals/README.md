# Evals

Behaviour tests for the `site-triage` skill, run with `claude plugin eval` (Claude Code 2.1.269 or later — the release that added the command,
per the [Claude Code changelog](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md), read 2026-10-25).
`claude plugin validate` checks the files; these check what the skill makes Claude do.

The suite ships inside the plugin on purpose: `claude plugin eval` only reads an eval directory
below the plugin (`--eval-dir` must be a relative path inside it — checked 2026-10-25 on 2.1.310),
so an installed copy can run the same cases. Nothing in it loads during normal use.

```bash
claude plugin eval plugins/site-triage --scaffold --no-publish --max-cost-usd 6
```

`--scaffold` is needed by `brand-only`, which writes a small fixture site with
`brand-only/fixture.sh`. Without it that case runs in an empty folder and fails.

| Case | Asserts |
|---|---|
| `trigger-gsc-en`, `trigger-gsc-tr`, `trigger-gsc-tr-labels` | The skill fires on a Search Console question (English, colloquial Turkish, Turkish report labels) and loads `16-search-console.md` |
| `trigger-tr-label-only` | The skill fires on a Turkish status label alone, with no product name in the prompt |
| `no-trigger`, `no-trigger-tr` | The skill stays out of an unrelated coding question (English and Turkish) |
| `no-fabricated-verdicts` | With no network, no check is reported as passed or failed (rule 2) |
| `healthy-redirects` | Slashless twins that 308 once are read as expected, not as defects (rule 1) |
| `brand-only` | Mode C reports brand findings only (scan steps 1-3) |
| `geo-tool-disagreement` | A GeoDaddy finding that the references show to be wrong is flagged, not repeated (rule 3) |

GeoDaddy is mocked in `mocks/geodaddy/`; the real server never starts unless `--mocks off` or
`--allow-real-servers` is passed. The mock body is a hand-written fixture in the shape the tool
describes (score, categories, findings), not a recorded response.

On a machine where the skill is also installed in a skills directory, the no-plugin baseline arm
still sees it, so read the with-plugin scores and ignore the delta there.

Last full run (2026-10-24, Claude Code 2.1.310, three runs per case, `--ablation none`): 20 of 21
runs passed, 3.63 USD. `trigger-gsc-tr` did not fire the skill in one of three runs. That is a
triggering result to act on in the skill's description, not a grader to loosen. With the default
`--threshold 1.0` one such run makes the command exit 1.

Turkish labels were then added to the description. The six trigger cases scored 18 of 18 runs both
before and after the change, and the negatives 6 of 6. At three runs per case the suite cannot
tell the two descriptions apart.

On 2026-10-25 the labels moved out of the description into a Turkish column in
`16-search-console.md` (Claude Code 2.1.310, three runs per case): the four trigger cases scored 12 of
12, the Turkish ones included, and the negatives 6 of 6.

Each run costs money: the 2026-10-24 full run averaged about 0.17 USD per run (3.63 USD for 21
runs) with the default model.
Results land in `evals/results/`, which is gitignored.
