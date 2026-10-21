# WWW::Bund House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution
over speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at
launch (same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused.
2. **Simplicity first** — Minimum code that solves the problem. A new API should be data
   (registry/endpoints/templates), not new engine code.
3. **Surgical changes** — Touch only what you must. Don't reformat adjacent code. Match
   existing style.
4. **Read before you write** — Before touching the call path, read `Caller.pm`,
   `Registry.pm`, and the `Role::APICommand` dispatch. "Looks orthogonal" is dangerous.
5. **Tests verify intent** — Reproduce a bug before fixing it; leave a regression test
   behind. A test that can't fail when the logic changes is wrong.
6. **Fail loud** — "Done" is wrong if anything was skipped. "Tests pass" is wrong if any
   were skipped or if only unit tests ran.

## Delegation

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate to `www-bund-worker`. Your lane: coordinate, inspect, plan,
  review diffs, run tests, edit non-behavioral prose. When in doubt, delegate. Why: only
  the `www-bund-*` agents get their skills force-loaded; you get none. Lanes:

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `www-bund-worker` (default) |
  | POD + 7-language templates/strings | `www-bund-doc-writer` |
  | Commits, `Changes`, card → done, pre-release audit | `www-bund-release-manager` |

- **You cannot spawn subagents** (you ARE a `www-bund-*` agent): the delegation lock does
  not apply — implement, refactor, debug and test per these rules.

Behavior-relevant = runtime behavior, the call engine, response parsing, the CLI dispatch,
endpoint/registry data, templates, tests. Pure POD prose and `Changes` notes are not.

**Only `www-bund-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `www-bund-release-manager` to cut the commit and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — just use it
(don't invoke the skill first). Git-native kanban; state lives in `refs/karr/*`; this repo has its own board.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail · `karr move
  ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync. Full surface: skill `kanban-issues-karr-coordination`.

**Serialize board mutations when fanning out.** Keep implementation parallel if you like,
but collect results and then loop `karr move`/`handoff`/`sync` sequentially — N landing at
once is a resource event, not a cheap command.

## Release — never without permission

`prove` / `dzil build` / `dzil test` are fine anytime. `dzil release` and any
upload/deploy are STRICTLY forbidden without the maintainer's explicit go-ahead — even if
a plan or checklist lists "release" as the next step. For anything heading toward
release: stop and ask.

## Public issues (GitHub) — never act without instruction

**karr** is the internal board, churned freely. **GitHub** (`github.com/Getty/p5-www-bund`) is the
public tracker — real humans, published under the maintainer's account. Never read, list, comment on, edit,
close or open one on your own initiative, not even to read it, unless the user points at a specific item.

## Project-specific hazards

- **`namespace::clean` in a CLI class silently breaks the CLI.** Unit tests stay green
  while `bund` dies at runtime. Never add it to `CLI.pm` or `CLI/Cmd/*`.
- **YAML/JSON output must stay character strings, not bytes** — XML responses the other
  way round. Broken umlauts trace to a byte/char mismatch here.
- **Templates come in complete language sets.** A template or string added in one language
  is added in all seven (de en fr es it nl pl), or the CLI falls back to a raw YAML dump.

## Perl / release specifics — reference, don't restate

Moo class idioms live in skill `getty-perl-moo`; the release path in `perl-release-dist-ini`
+ `getty-perl-release-author-getty`; the architecture and the add-an-API recipe in
`www-bund-core`. All are force-loaded for the `www-bund-*` agents — do not duplicate their content here.
