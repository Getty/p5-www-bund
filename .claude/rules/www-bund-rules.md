# WWW::Bund House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Perl client for German Federal Government APIs (bund.dev). Read first, before touching the
call path: `Caller.pm`, `Registry.pm`, and the `Role::APICommand` dispatch.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-bund-worker` (default) |
| POD + 7-language templates/strings | `www-bund-doc-writer` |
| Commits, `Changes`, card → done, pre-release audit | `www-bund-release-manager` |
| Read-only research, audit, gap analysis | `www-bund-worker` ("read-only, change nothing") |

Behavior-relevant = runtime behavior, the call engine, response parsing, the CLI dispatch,
endpoint/registry data, templates, tests. Pure POD prose and `Changes` notes are not.

## Hazards

- **A new API is data, not engine code** — registry, endpoints, templates. Reaching into the
  call engine for one API is the wrong shape.
- **Unit tests alone are not "tests pass".** Say so when only unit tests ran.
- **`namespace::clean` in a CLI class silently breaks the CLI.** Unit tests stay green while
  `bund` dies at runtime. Never add it to `CLI.pm` or `CLI/Cmd/*`.
- **YAML/JSON output must stay character strings, not bytes** — XML responses the other way
  round. Broken umlauts trace to a byte/char mismatch here.
- **Templates come in complete language sets.** A template or string added in one language is
  added in all seven (de en fr es it nl pl), or the CLI falls back to a raw YAML dump.

## Perl / release specifics — reference, don't restate

Moo class idioms live in skill `getty-perl-moo`; the release path in `perl-release-dist-ini` +
`getty-perl-release-author-getty`; the architecture and the add-an-API recipe in
`www-bund-core`. All are force-loaded for the `www-bund-*` agents.
