# create-gem

Interactive wizard for `bundle gem`.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add create-gem
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install create-gem
```

## Usage

```bash
create-gem my_gem
create-gem --list-presets
create-gem --show-preset my-defaults
create-gem my_gem --preset my-defaults
create-gem my_gem --preset my-defaults --dry-run
create-gem my_gem --save-preset my-defaults
create-gem --delete-preset my-defaults
create-gem --doctor
create-gem --version
```

Config is stored at `~/.config/create-gem/config.yml`.

Interactive mode behavior:
- Press Enter to keep the default choice on each step.
- Press `Ctrl+C` to exit at any time.
- Press `Ctrl+B` to revisit the previous step.
- Defaults are always shown as option `1`.
- Each step includes a short plain-English explanation.
- The wizard marks the current default variant as `option (default)`.
- Summary shows the exact `bundle gem` command.

Version behavior:
- Detects Ruby, RubyGems, and Bundler versions at runtime.
- Uses a static Bundler compatibility matrix to expose only supported options.

## Release

Versioning:
- Follow SemVer.
- Use `0.x.y` for pre-1.0 development.
- Bump:
  - patch for bug fixes,
  - minor for backward-compatible features,
  - major for breaking changes.

Release checklist:
1. Update `lib/create_gem/version.rb`.
2. Update `CHANGELOG.md` under `[Unreleased]` and cut a version section.
3. Run `bundle exec rake`.
4. Run `bundle exec rake release`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/leonid-svyatov/create-gem.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
