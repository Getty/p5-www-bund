# CLAUDE.md — WWW::Bund

**WWW::Bund** is a Moo client and multilingual CLI (`bund` + per-language
variants) for the German federal APIs on bund.dev — a generic call engine, a
registry of endpoints, and a 7-language template renderer.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it
yourself — the principle and the lane split are in
`.claude/rules/www-bund-rules.md` (auto-loaded every turn).

| Task | Agent |
|---|---|
| Implement / refactor / debug / test behavior-relevant code | `www-bund-worker` (default) |
| POD + 7-language templates/strings | `www-bund-doc-writer` |
| Commits, `Changes`, card → done, pre-release audit | `www-bund-release-manager` |

The agents carry their knowledge via `briefing.skills` (see `.claude/agents/`);
the main agent delegates rather than loading those skills. Architecture, the
add-an-API recipe, the template/UTF-8/XML conventions, and the invariants live
in the `www-bund-core` skill under `.claude/skills/`. Shared Perl and release
skills (`getty-perl-moo`, `perl-release-dist-ini`,
`getty-perl-release-author-getty`) are hardlinked there too.

## Coordination

Work is tracked on this repo's `karr` board (`karr board`). Release
(`dzil release`) is never run without the maintainer's explicit go-ahead.
