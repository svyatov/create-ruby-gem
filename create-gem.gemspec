# frozen_string_literal: true

require_relative 'lib/create_gem/version'

Gem::Specification.new do |spec|
  spec.name = 'create-gem'
  spec.version = CreateGem::VERSION
  spec.authors = ['Leonid Svyatov']
  spec.email = ['leonid@svyatov.com']

  spec.summary = 'Interactive wizard for bundle gem'
  spec.description = 'Fast TUI for scaffolding Ruby gems with presets and remembered options.'
  spec.homepage = 'https://github.com/leonid-svyatov/create-gem'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.2')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/leonid-svyatov/create-gem/blob/main/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/create-gem'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/leonid-svyatov/create-gem/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob(%w[lib/**/*.rb exe/*]) + %w[LICENSE.txt README.md CHANGELOG.md]
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'cli-kit', '= 5.0.1'
  spec.add_dependency 'cli-ui', '= 2.7.0'
end
