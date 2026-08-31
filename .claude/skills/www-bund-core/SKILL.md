---
name: www-bund-core
description: "Architecture, invariants and the add-an-API recipe for WWW::Bund — the Moo client + multilingual CLI for the bund.dev federal APIs. Load when implementing, debugging or documenting anything in this distribution: CLI commands, the call engine, response parsing, the 7-language template/string system, or UTF-8/XML handling."
---

# WWW::Bund — architecture and house conventions

WWW::Bund is a **Moo** client and a multilingual CLI (`bund` + per-language
variants) for the German federal APIs on bund.dev. One generic call engine,
one registry of endpoints, one template renderer — new APIs are almost pure
data, not code.

## The two-layer shape

**Data plane** (`lib/WWW/Bund/`, library classes — these DO use
`namespace::clean`):

- `Registry.pm` — loads `share/registry.yml` (API metadata) and
  `share/endpoints.yml` (endpoint metadata) and answers lookups.
- `Caller.pm` — the generic call engine. Endpoint lookup → URL build →
  param substitution → rate-limit → cache (GET) → auth headers → IO → parse.
- `Cache.pm` (XDG disk cache, per-endpoint TTL), `Auth.pm`, `RateLimit.pm`.
- `LWPIO.pm` implements `Role::IO`; tests swap in a MockIO.
- `Response/{JSON,XML,Raw}.pm` — content-type/sniff dispatch in
  `Caller::_build_response`.

**CLI plane** (`lib/WWW/Bund/CLI/`, MooX::Cmd + MooX::Options):

- `CLI.pm` — root: global options `--output`/`-o`, `--lang`, `--template`/`-t`;
  helpers `_resolve_api`, `_action_to_endpoint`, `cmd_list`/`cmd_info`/`cmd_call`.
- `CLI/Role/APICommand.pm` — the dispatch role: `requires 'api_id'`, generic
  `execute` that calls the root's `cmd_api_help` (no args) or `cmd_call`.
- `CLI/Cmd/*.pm` — one class per API, **~10 LOC each**.
- `CLI/Formatter.pm` — template renderer. `CLI/Strings.pm` — localized strings.

## Invariant: no `namespace::clean` in CLI classes

`CLI.pm`, `CLI/Cmd/*`, and any class consuming MooX::Options must **not** use
`namespace::clean`. It strips MooX::Options' injected methods
(`_options_data`, `_options_config`) and the CLI breaks at runtime with green
unit tests. Library/data-plane classes use `namespace::clean` normally.

## Adding an API — the recipe

Almost all of it is data. A new API command class is boilerplate:

```perl
package WWW::Bund::CLI::Cmd::MyApi;
our $VERSION = '0.003';
# ABSTRACT: MyApi API commands
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;
with 'WWW::Bund::CLI::Role::APICommand';
sub api_id { 'my_api' }
1;
```

1. Check `share/registry.yml` for the API id (`- id:` entries).
2. Add endpoints to `share/endpoints.yml`: `name: {api_id}_{action}`
   (snake_case), `api:`, `base_url:` (from the OpenAPI spec `servers[0].url`),
   `path:`, `method:`, `cache_ttl:` matched to data freshness, optional
   `query_params:`.
3. Write `lib/WWW/Bund/CLI/Cmd/{ApiName}.pm` (the boilerplate above).
4. If the CLI verb differs from the class name, add a `%aliases` entry in the
   `bin/bund*` scripts (e.g. `eco-visio`→`ecovisio`, `pegel-online`→`pegel`).
5. Add the class to `t/00-load.t`.
6. Live-test: `perl -Ilib bin/bund my-api action`.
7. Create a template `{api_id}_{action}.yml` in **all 7** language folders.

### base_url / path parameters and POST bodies (already supported)

`Caller` substitutes `{param}` placeholders in **both** `base_url` and `path`
from the call `params` (e.g. `{region}` for abfallnavi's regional hosts).
Leftover params become the query string for **GET**, or a
`application/x-www-form-urlencoded` **body** for **POST/PUT**. So regional
hosts and form-POST APIs need only endpoint data — do not re-add these as
Caller features.

## The 7-language template system

Languages: **de en fr es it nl pl**. `bund` defaults to de; `bunden`/`bundfr`/…
set `WWW_BUND_LANG`; `--lang XX` overrides at runtime.

- Templates live at `share/templates/{lang}/{endpoint_name}.yml`, **keyed by the
  endpoint name** — the original (mostly German) API identifier. **Never
  translate file or endpoint names**; only translate the `header`/`label`/`empty`
  text *inside* the template.
- Strings live at `share/strings/{lang}.yml`; `Strings->get($key, @sprintf_args)`
  returns the key itself when missing (graceful degradation).
- **Adding a language** = new `templates/{lang}/` folder + `strings/{lang}.yml`.

Template shape (`Formatter`):

- `type: table` — `columns:` of `{field, header, width, wrap}`; auto-sizes,
  never narrower than the header, caps at `width`, truncates or word-wraps;
  `full_grid: 1` for box borders. Data must be an array.
- `type: list` — one value per line, or `columns: N` for N-up; picks
  `field:` or falls back to name/shortname/title/id.
- `type: record` — `fields:` of `{field, label}` for a single hash.
- `extract: dotted.path` — drill into the response before rendering.
- `empty: "…"` — message when the array is empty / path missing.
- Dotted `field` paths (`water.shortname`) navigate nested hashes.
- No template found → **YAML fallback** (the raw structure is dumped).

## UTF-8 — the rules that actually bite

- `bin/bund*` set `binmode(STDOUT/STDERR, ':encoding(UTF-8)')`.
- The formatter **always returns character strings, never bytes**:
  - JSON: `JSON::MaybeXS->new(utf8 => 0)` → character strings.
  - YAML: `YAML::PP`'s `Dump` returns character strings — no manual decode.
    (Legacy notes about `YAML::XS` + `decode('UTF-8', …)` are obsolete.)
  - Booleans are dereffed (`_deref_booleans`) for JSON/YAML and rendered via
    the `bool_true`/`bool_false` strings in templates.
- Writing template files: native `open(..., '>:encoding(UTF-8)', ...)`, **not**
  `File::Slurp` (encoding breakage).
- **XML (Bundestag, Bundesrat)**: `LWP` gives decoded character strings, but
  `XML::Parser` needs **bytes** — `Response::XML` does `encode_utf8` when
  `utf8::is_utf8` is true before `$twig->parse`. The disk cache must store the
  raw bytes (`:raw`) to avoid Latin-1 corruption on re-read.

## Cache TTL guidance

Per-endpoint `cache_ttl` in `endpoints.yml`, GET-only:
`120` emergencies/warnings (NINA, DWD, Autobahn warnings) · `300` realtime
(Tagesschau, Pegel readings, roadworks) · `1800` moderate (webcams, search,
timeseries) · `86400` static (road/station lists, metadata).

## Tests

`prove -l t/` (all). Notable files: `t/00-load.t` (module loading — update on
every new class), `t/caller.t` (MockIO implementing `Role::IO`), `t/cli.t`
(subprocess: `$^X -Ilib bin/bund …`), `t/integration.t` (live, opt-in via
`WWW_BUND_LIVE_TEST=1`). MooX::Options auto-generates `--help`, so CLI tests
assert on options text, not on overview prose.
