## [Unreleased]

- Initial release: interactive wizard for `bundle gem` with back/edit/cancel flow, summary diff, and preset save prompt.
- Add preset commands: `--list-presets`, `--show-preset`, `--delete-preset`, and `--preset` non-interactive creation.
- Add runtime diagnostics: `--doctor` and `--version`.
- Add static Bundler compatibility matrix with explicit unsupported-version errors.
- Add integration tests that execute real `bundle gem` runs in temporary directories.
- Expand CI to test Bundler version matrix across Ruby 3.2-4.0.
