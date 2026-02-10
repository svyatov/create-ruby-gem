# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

`create-gem` is an interactive TUI wizard wrapping `bundle gem`. It detects the user's Ruby/Bundler versions, shows only compatible options via a static compatibility matrix, and builds the correct `bundle gem` command. Config (presets, last-used options) is stored in `~/.config/create-gem/config.yml`.

## Commands

```bash
bundle exec rake          # run tests + rubocop (default task)
bundle exec rake spec     # tests only
bundle exec rake rubocop  # lint only (with --parallel --autocorrect)
bundle exec rspec spec/create_gem/cli_spec.rb          # single test file
bundle exec rspec spec/create_gem/cli_spec.rb:42       # single example by line
bin/console               # IRB with gem loaded
exe/create-gem            # run the CLI locally
```

## Architecture

Entry point: `exe/create-gem` → `CreateGem::CLI.start(ARGV)`.

Key flow: CLI parses flags → detects runtime versions → looks up `Compatibility::Matrix` entry for the Bundler version → runs `Wizard::Session` (interactive) or loads a preset → `Command::Builder` assembles the `bundle gem` command array → `Runner` executes it.

### Core modules

- **`CLI`** — option parsing (`OptionParser`), flag validation, orchestrates the entire flow. All collaborators are injected via constructor for testability.
- **`Compatibility::Matrix`** — static `TABLE` of `Entry` structs mapping Bundler version ranges (2.4–2.x, 3.x, 4.x) to supported `bundle gem` options. Single source of truth for what each Bundler version supports.
- **`Options::Catalog`** — defines every `bundle gem` option (type: `:toggle`, `:flag`, `:enum`, `:string`) with its CLI flags. `ORDER` array controls wizard step sequence.
- **`Options::Validator`** — validates user-selected options against the compatibility entry.
- **`Wizard::Session`** — step-by-step interactive prompt loop with back-navigation (`Ctrl+B`). Uses `Prompter` for all I/O.
- **`Command::Builder`** — converts option hash into a `['bundle', 'gem', name, ...]` array.
- **`Config::Store`** — YAML persistence for presets and last-used options. Atomic writes via `Tempfile` + rename.
- **`Runner`** — shells out via `CLI::Kit::System.system`. Supports `--dry-run`.
- **`UI::Prompter`** — thin wrapper around `cli-ui` gem. All user interaction goes through this (for test doubles).
- **`UI::Palette`** — color constants for terminal output.

### Option type system

Options in `Catalog::DEFINITIONS` use four types:
- `:toggle` — boolean, emits `--flag` / `--no-flag`
- `:flag` — opt-in only, emits `--flag` when true, nothing when false
- `:enum` — pick one value from a list, emits `--flag=value` or `--no-flag`
- `:string` — free text, emits `--flag=value`

## Dependencies

- **cli-ui** (2.7.0) — interactive prompts, frames, colors
- **cli-kit** (5.0.1) — system command execution

## CI

GitHub Actions matrix: Ruby 3.2–4.0 × Bundler 2.4–4.0. Runs `bundle exec rake` (spec + rubocop).

## Conventions

- Ruby >= 3.2. `frozen_string_literal: true` everywhere.
- RSpec with `expect` syntax only, monkey patching disabled.
- Version in `lib/create_gem/version.rb`. SemVer, currently `0.x.y`.
