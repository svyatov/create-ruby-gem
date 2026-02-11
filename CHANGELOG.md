# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
and [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## [Unreleased]

## [0.1.1] - 2026-02-11

### Fixed

- Crash on Ruby 4.0 / RubyGems 4.0 where `Bundler.settings` was unavailable because Bundler was only partially loaded.

## [0.1.0] - 2026-02-10

### Added

- Interactive wizard for `bundle gem` with back/edit/cancel flow, command summary, and preset save prompt.
- Preset commands: `--list-presets`, `--show-preset`, `--delete-preset`, and `--preset` for non-interactive creation.
- Runtime diagnostics: `--doctor` and `--version`.
- Static Bundler compatibility matrix with explicit unsupported-version errors.
- Integration tests that execute real `bundle gem` runs in temporary directories.
- CI matrix testing Bundler versions across Ruby 3.2–4.0.
- YARD documentation for all source files.
- Production-ready README with compatibility matrix, CLI reference, and preset examples.
