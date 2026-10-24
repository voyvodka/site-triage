# Evals

Behaviour tests for the `site-triage` skill, run with `claude plugin eval` (Claude Code 2.1.269 or later).
`claude plugin validate` checks the files; these check what the skill makes Claude do.

```bash
claude plugin eval plugins/site-triage --scaffold --no-publish --max-cost-usd 6
```

`--scaffold` is needed by `brand-only`, which writes a small fixture site with
`brand-only/fixture.sh`. Without it that case runs in an empty folder and fails.

| Case | Asserts |
|---|---|
| `trigger-gsc-en`, `trigger-gsc-tr` | The skill fires on a Search Console question (English and Turkish) and loads `16-search-console.md` |
| `no-trigger` | The skill stays out of an unrelated coding question |
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

Each run costs money: about 0.05-0.30 USD per run with the default model, three runs per case.
Results land in `evals/results/`, which is gitignored.
