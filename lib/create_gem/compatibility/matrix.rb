# frozen_string_literal: true

module CreateGem
  module Compatibility
    class Matrix
      Entry = Struct.new(:requirement, :supported_options, keyword_init: true) do
        def match?(bundler_version)
          requirement.satisfied_by?(bundler_version)
        end

        def supports_option?(option_key)
          supported_options.key?(option_key.to_sym)
        end

        def allowed_values(option_key)
          supported_options.fetch(option_key.to_sym)
        end
      end

      TABLE = [
        Entry.new(
          requirement: Gem::Requirement.new('>= 2.4', '< 3.0'),
          supported_options: {
            exe: nil,
            coc: nil,
            ext: %w[c],
            git: nil,
            github_username: nil,
            mit: nil,
            test: %w[minitest rspec test-unit],
            ci: %w[circle github gitlab],
            edit: nil,
            bundle_install: nil
          }
        ),
        Entry.new(
          requirement: Gem::Requirement.new('>= 3.0', '< 4.0'),
          supported_options: {
            exe: nil,
            coc: nil,
            changelog: nil,
            ext: %w[c],
            git: nil,
            github_username: nil,
            mit: nil,
            test: %w[minitest rspec test-unit],
            ci: %w[circle github gitlab],
            linter: %w[rubocop standard],
            edit: nil,
            bundle_install: nil
          }
        ),
        Entry.new(
          requirement: Gem::Requirement.new('>= 4.0', '< 5.0'),
          supported_options: {
            exe: nil,
            coc: nil,
            changelog: nil,
            ext: %w[c go rust],
            git: nil,
            github_username: nil,
            mit: nil,
            test: %w[minitest rspec test-unit],
            ci: %w[circle github gitlab],
            linter: %w[rubocop standard],
            edit: nil,
            bundle_install: nil
          }
        )
      ].freeze

      def self.supported_ranges
        TABLE.map { |entry| entry.requirement.requirements.map(&:join).join(', ') }
      end

      def self.for(bundler_version)
        version = Gem::Version.new(bundler_version.to_s)
        entry = TABLE.find { |candidate| candidate.match?(version) }
        return entry if entry

        message = "Unsupported bundler version: #{version}. "
        message += "Supported ranges: #{supported_ranges.join(' | ')}"
        raise UnsupportedBundlerVersionError, message
      end
    end
  end
end
