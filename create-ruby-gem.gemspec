# frozen_string_literal: true

require_relative 'lib/create_ruby_gem/version'

Gem::Specification.new do |spec|
  spec.name = 'create-ruby-gem'
  spec.version = CreateRubyGem::VERSION
  spec.authors = ['Leonid Svyatov']
  spec.email = ['leonid@svyatov.com']

  spec.summary = 'Create Ruby gems with an interactive CLI wizard that remembers your choices'
  spec.description = 'Interactive CLI wizard for bundle gem. ' \
                     'Walks you through every option, saves presets, and remembers your choices. ' \
                     'No more bundle gem flags look-ups!'
  spec.homepage = 'https://github.com/svyatov/create-ruby-gem'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.2')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['changelog_uri'] = 'https://github.com/svyatov/create-ruby-gem/blob/main/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/create-ruby-gem'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/svyatov/create-ruby-gem/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob(%w[lib/**/*.rb exe/*]) + %w[LICENSE.txt README.md CHANGELOG.md]
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'cli-kit', '= 5.0.1'
  spec.add_dependency 'cli-ui', '= 2.7.0'
end
