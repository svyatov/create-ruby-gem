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

Key flow: CLI parses flags → detects runtime versions → looks up `Compatibility::Matrix` entry for the Bundler version → runs `Wizard` (interactive) or loads a preset → validates options → `CommandBuilder` assembles the `bundle gem` command array → `Runner` executes it.

### Core modules

- **`CLI`** — option parsing (`OptionParser`), flag validation, orchestrates the entire flow. All collaborators are injected via constructor for testability.
- **`Detection::BundlerVersion`** — detects installed Bundler version via `bundle --version`.
- **`Detection::BundlerDefaults`** — reads Bundler's own default settings from `~/.bundle/config`.
- **`Detection::Runtime`** — detects Ruby, RubyGems, and Bundler versions. Returns a `Detection::RuntimeInfo` struct.
- **`Compatibility::Matrix`** — static `TABLE` of `Entry` structs mapping Bundler version ranges (2.4–2.x, 3.x, 4.x) to supported `bundle gem` options. Single source of truth for what each Bundler version supports.
- **`Options::Catalog`** — defines every `bundle gem` option (type: `:toggle`, `:flag`, `:enum`, `:string`) with its CLI flags. `ORDER` array controls wizard step sequence.
- **`Options::Validator`** — validates user-selected options against the compatibility entry.
- **`Wizard`** — step-by-step interactive prompt loop with back-navigation (`Ctrl+B`). Uses `Prompter` for all I/O.
- **`CommandBuilder`** — converts option hash into a `['bundle', 'gem', name, ...]` array. Pure translator (validation is done by CLI before building).
- **`Config::Store`** — YAML persistence for presets and last-used options. Atomic writes via `Tempfile` + rename.
- **`Runner`** — shells out via `CLI::Kit::System.system`. Supports `--dry-run`.
- **`UI::Prompter`** — thin wrapper around `cli-ui` gem. All user interaction goes through this (for test doubles). Call `Prompter.setup!` once before use.
- **`UI::Palette`** — color constants for terminal output.
- **`UI::BackNavigationPatch`** — monkey-patches `CLI::UI::Prompt` to intercept Ctrl+B.

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

## Documentation Style

All classes and methods must have YARD documentation. Follow these conventions:

- Always leave a **blank line** between the main description and `@` attributes (params, return, etc.)
- Document all public methods with description, params, and return types
- Document all private methods with params and return types, add description for complex logic
- Include `@example` blocks for non-obvious usage patterns
- Use `@raise` to document exceptions
- **Omit descriptions that just repeat the code** - if the method name and signature make it obvious, only include `@param`, `@return`, and `@raise` tags without a description

```ruby
# Good - blank line before @param
# Calculates the check digit for this identifier.
#
# @param value [String] the value to calculate
# @return [Integer] the calculated check digit
def calculate(value)
end

# Bad - no blank line
# Calculates the check digit for this identifier.
# @param value [String] the value to calculate
# @return [Integer] the calculated check digit
def calculate(value)
end
```

## Pre-Commit Checklist

Before committing changes, always verify these files are updated to accurately reflect the changes:

- **CLAUDE.md** - Update this file
- **README.md** - Update usage examples, Table of Contents, and compatibility matrix
- **CHANGELOG.md** - Add entry under `[Unreleased]` section describing the change (use only standard Keep a Changelog categories — see sec_id's CLAUDE.md for the canonical list)
- **create-gem.gemspec** - Update `description` if adding/removing supported features

## Releasing a New Version

This project follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html):
- **MAJOR** — breaking changes (incompatible API changes)
- **MINOR** — new features (backwards-compatible)
- **PATCH** — bug fixes (backwards-compatible)

1. Update `lib/create_gem/version.rb` with the new version number
2. Update `CHANGELOG.md`: change `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD` and add new empty `[Unreleased]` section
3. Commit changes: `git commit -am "chore: bump version to X.Y.Z"`
4. Release: `bundle exec rake release` — builds the gem, creates and pushes the git tag, pushes to RubyGems.org
5. Create GitHub release at https://github.com/leonid-svyatov/create-gem/releases with notes from CHANGELOG
