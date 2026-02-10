# frozen_string_literal: true

module CreateGem
  module Compatibility
    # Static lookup table mapping Bundler version ranges to the +bundle gem+
    # options each range supports.
    #
    # This is the single source of truth for what each Bundler version
    # can do. The wizard, validator, and builder all consult it.
    #
    # @example Look up the entry for a specific Bundler version
    #   entry = Matrix.for('3.1.0')
    #   entry.supports_option?(:linter)  #=> true
    class Matrix
      # A single row in the compatibility table.
      #
      # @!attribute [r] requirement
      #   @return [Gem::Requirement] Bundler version range this entry covers
      # @!attribute [r] supported_options
      #   @return [Hash{Symbol => Array<String>, nil}] option keys to allowed
      #     values (+nil+ means any boolean/toggle value is accepted)
      Entry = Struct.new(:requirement, :supported_options, keyword_init: true) do
        # @param bundler_version [Gem::Version] version to test
        # @return [Boolean]
        def match?(bundler_version)
          requirement.satisfied_by?(bundler_version)
        end

        # @param option_key [Symbol, String]
        # @return [Boolean]
        def supports_option?(option_key)
          supported_options.key?(option_key.to_sym)
        end

        # @param option_key [Symbol, String]
        # @return [Array<String>, nil] allowed values, or nil for toggles/flags
        def allowed_values(option_key)
          supported_options.fetch(option_key.to_sym)
        end
      end

      # @return [Array<Entry>] all known Bundler compatibility entries
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

      # Returns human-readable version range strings for all entries.
      #
      # @return [Array<String>]
      def self.supported_ranges
        TABLE.map { |entry| entry.requirement.requirements.map(&:join).join(', ') }
      end

      # Finds the compatibility entry for the given Bundler version.
      #
      # @param bundler_version [Gem::Version, String] the Bundler version
      # @return [Entry]
      # @raise [UnsupportedBundlerVersionError] if no entry matches
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
