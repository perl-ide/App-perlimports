# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`App::perlimports` is a Perl CLI tool and library that automates cleanup of Perl `use` import statements — making implicit imports explicit and removing unused ones. It requires Perl 5.18+.

## Commands

**Run all tests:**
```bash
prove -lr -j2 t
```

**Run a single test file:**
```bash
prove -l t/cli.t
```

**Lint all code:**
```bash
precious lint --all
```

**Tidy all code:**
```bash
precious tidy --all
```

**Build the distribution (requires Dist::Zilla):**
```bash
dzil build
```

## Code Quality Tools

`precious.toml` configures:
- `perlimports` — run via `perl -Ilib script/perlimports`, with `--lint` for linting or `-i` for tidying
- `perltidy` — formatter governed by `perltidyrc` (4-space indent, 78-char lines)
- `perlcritic` — style checker governed by `perlcriticrc` (severity 3)
- `omegasort` — sorts `.gitignore` and `.stopwords`

## Architecture

The tool is built on [PPI](https://metacpan.org/pod/PPI) (Perl Parse Interface) and uses [Moo](https://metacpan.org/pod/Moo) for its object system with [Types::Standard](https://metacpan.org/pod/Types::Standard) for validation.

**Data flow:**
```
CLI -> Document -> Include -> ExportInspector -> Sandbox
         |-> Config
         |-> Annotations
         |-> PPI (parse tree)
```

**Key modules in `lib/App/perlimports/`:**

- **CLI.pm** — Parses CLI arguments, manages I/O (file or stdin), dispatches to Document. Handles `--inplace-edit`, `--json`, `--lint`, `--config`. Discovers config via `XDG_CONFIG_HOME` when `--config` is not specified.
- **Document.pm** — Core logic. Wraps `PPI::Document`, identifies all imports in a file, determines which symbols are actually used, and coordinates rewriting.
- **Include.pm** — Represents a single `use Module ...` statement. Tracks which exported symbols are used and formats the corrected import line.
- **ExportInspector.pm** — Inspects a module's `@EXPORT`, `@EXPORT_OK`, and `@EXPORT_TAGS` by loading it in a sandboxed `eval`. Handles both `Exporter` and `Sub::Exporter` styles.
- **Config.pm** — Reads `perlimports.toml`. Manages ignore lists, lib paths, logging, and output format.
- **Annotations.pm** — Parses `## no perlimports` / `## use perlimports` inline comment directives that let users disable or re-enable the tool for ranges of code.
- **Sandbox.pm** — Provides an isolated environment for safely evaluating module exports without polluting the main namespace.

**Entry points:**
- `script/perlimports` — Thin CLI script that delegates to `App::perlimports::CLI`.
- `script/dump-perl-exports` — Utility to inspect a module's exports directly.

## Test Layout

- `t/*.t` — Main test suite (~85 files)
- `t/ExportInspector/` — Tests specific to export inspection logic
- `t/cpan-modules/` — Integration tests against real CPAN modules
- `t/lib/` — Shared test utilities (`TestHelper.pm`)
- `test-data/lib/` — Sample Perl modules used as test fixtures

## Dependencies

Declared in `cpanfile`. The build is managed by [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) via `dist.ini` — **do not edit `Makefile.PL` directly**, it is generated.

## Development Notes

- The `perlimports.toml` at the repo root configures the tool for its own source (libs: `lib` and `t/lib`).
- Attributes in the Moo classes use lazy initialization extensively — be careful when adding new attributes that existing tests may not exercise lazy code paths.
- A pre-commit hook (`git/hooks/pre-commit`) runs `precious lint --staged`; install it with `bash git/setup.sh`.
- PPI is a regular CPAN dependency (version 1.276 minimum), not a fork.
