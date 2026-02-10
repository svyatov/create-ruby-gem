# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
and [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## [Unreleased]

### Changed

- Grouped detectors under `Detection` namespace: `Detection::BundlerDefaults`, `Detection::BundlerVersion`, `Detection::Runtime`.
- Renamed `RuntimeVersions::Versions` to `Detection::RuntimeInfo`.
- Flattened `Command::Builder` to `CommandBuilder` and `Wizard::Session` to `Wizard`.
- Renamed `UI::InteractiveKeymap` to `UI::BackNavigationPatch`.
- Renamed `CLI#start` instance method to `CLI#run` (class method `CLI.start` unchanged).
- `CommandBuilder` now accepts `compatibility_entry:` instead of `bundler_version:`.
- Separated validation from `CommandBuilder` — `Options::Validator` is now called by CLI before building.
- Extracted `UI::Prompter.setup!` class method for global side effects (stdout router, Ctrl+B patch).
- Made `UI::Palette` injectable in CLI via `palette:` keyword.
- Replaced magic string sentinels (`'__back__'`, `'__bundler_default__'`) with `Object.new.freeze`.

### Added

- Interactive wizard for `bundle gem` with back/edit/cancel flow, summary diff, and preset save prompt.
- Preset commands: `--list-presets`, `--show-preset`, `--delete-preset`, and `--preset` for non-interactive creation.
- Runtime diagnostics: `--doctor` and `--version`.
- Static Bundler compatibility matrix with explicit unsupported-version errors.
- Integration tests that execute real `bundle gem` runs in temporary directories.
- CI matrix testing Bundler versions across Ruby 3.2–4.0.
- YARD documentation for all source files.
- Production-ready README with compatibility matrix, CLI reference, and preset examples.
