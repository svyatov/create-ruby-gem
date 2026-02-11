# create-ruby-gem [![Gem Version](https://img.shields.io/gem/v/create-ruby-gem)](https://rubygems.org/gems/create-ruby-gem) [![CI](https://github.com/svyatov/create-ruby-gem/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/svyatov/create-ruby-gem/actions?query=workflow%3ACI)

> Create Ruby gems with an interactive CLI wizard, which remembers your choices!  
> No more `bundle gem` flags look-ups 🙌

## Table of Contents

- [Supported Versions](#supported-versions)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Interactive Wizard](#interactive-wizard)
- [Preset System](#preset-system)
- [Compatibility Matrix](#compatibility-matrix)
- [Configuration](#configuration)
- [CLI Reference](#cli-reference)
- [Development](#development)
- [Contributing](#contributing)
- [Changelog](#changelog)
- [Versioning](#versioning)
- [License](#license)

## Supported Versions

Ruby 3.2+ and Bundler 2.4+ are required.

## Installation

```bash
gem install create-ruby-gem
```

## Quick Start

```bash
create-ruby-gem my_awesome_gem
```

The wizard detects your Ruby and Bundler versions, walks you through every supported option, shows a summary of the `bundle gem` command it will run, and lets you edit or confirm before executing.

## Interactive Wizard

Running `create-ruby-gem <name>` starts the step-by-step wizard:

1. **Version detection** — detects Ruby, RubyGems, and Bundler versions at runtime.
2. **Option filtering** — shows only options your Bundler version supports (see [Compatibility Matrix](#compatibility-matrix)).
3. **Smart defaults** — uses your last-used choices as defaults, falling back to Bundler's own settings.
4. **Back-navigation** — press `Ctrl+B` to revisit the previous step.
5. **Summary** — displays the exact `bundle gem` command with color-coded arguments.
6. **Edit-again loop** — choose "edit again" to change options, or "create" to execute.
7. **Preset save prompt** — after creation, optionally save your choices as a named preset.

Press `Ctrl+C` at any time to exit.

## Preset System

Save, load, and manage option presets:

```bash
# Save options as a preset during gem creation
create-ruby-gem my_gem --save-preset oss-defaults

# Create a gem using a saved preset (non-interactive)
create-ruby-gem my_gem --preset oss-defaults

# List all saved presets
create-ruby-gem --list-presets

# Show a preset's options
create-ruby-gem --show-preset oss-defaults

# Delete a preset
create-ruby-gem --delete-preset oss-defaults
```

## Compatibility Matrix

Options available depend on your Bundler version. The wizard automatically hides unsupported options.

| Option | Bundler 2.4–2.x | Bundler 3.x | Bundler 4.x |
|--------|:---:|:---:|:---:|
| `--exe` / `--no-exe` | ✓ | ✓ | ✓ |
| `--coc` / `--no-coc` | ✓ | ✓ | ✓ |
| `--changelog` / `--no-changelog` | — | ✓ | ✓ |
| `--ext` | c | c | c, go, rust |
| `--git` | ✓ | ✓ | ✓ |
| `--github-username` | ✓ | ✓ | ✓ |
| `--mit` / `--no-mit` | ✓ | ✓ | ✓ |
| `--test` | minitest, rspec, test-unit | minitest, rspec, test-unit | minitest, rspec, test-unit |
| `--ci` | circle, github, gitlab | circle, github, gitlab | circle, github, gitlab |
| `--linter` | — | rubocop, standard | rubocop, standard |
| `--edit` | ✓ | ✓ | ✓ |
| `--bundle` / `--no-bundle` | ✓ | ✓ | ✓ |

## Configuration

Config is stored at `~/.config/create-ruby-gem/config.yml` (or `$XDG_CONFIG_HOME/create-ruby-gem/config.yml`).

The file contains:

- `version` — schema version (currently `1`)
- `last_used` — the options from your most recent gem creation
- `presets` — named option sets saved via `--save-preset` or the post-creation prompt

## CLI Reference

| Flag | Description |
|------|-------------|
| `<name>` | Gem name (prompted interactively if omitted) |
| `--preset NAME` | Use a saved preset (non-interactive) |
| `--save-preset NAME` | Save the selected options as a preset |
| `--list-presets` | List all saved preset names |
| `--show-preset NAME` | Show a preset's options |
| `--delete-preset NAME` | Delete a saved preset |
| `--dry-run` | Print the `bundle gem` command without executing |
| `--bundler-version VERSION` | Override the detected Bundler version |
| `--doctor` | Print runtime versions and supported options |
| `--version` | Print the create-ruby-gem version |

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `bundle exec rake` to run the tests and linter.
You can also run `bin/console` for an interactive prompt.

```bash
bundle exec rake          # tests + rubocop (default task)
bundle exec rake spec     # tests only
bundle exec rake yard     # generate YARD docs into doc/
exe/create-ruby-gem            # run the CLI locally
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make your changes and run tests (`bundle exec rake`)
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format (`git commit -m 'feat: add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes, following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
