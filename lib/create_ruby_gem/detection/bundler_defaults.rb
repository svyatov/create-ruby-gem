# frozen_string_literal: true

module CreateRubyGem
  module Detection
    # Reads Bundler's own default settings (from +~/.bundle/config+ or env)
    # to use as initial defaults in the wizard.
    class BundlerDefaults
      # Sentinel for "no settings argument provided".
      UNSET = Object.new.freeze

      # Fallback defaults used when Bundler settings are unavailable.
      #
      # @return [Hash{Symbol => Object}]
      FALLBACKS = {
        exe: false,
        coc: nil,
        changelog: nil,
        ext: false,
        git: true,
        github_username: nil,
        mit: nil,
        test: nil,
        ci: nil,
        linter: nil,
        edit: nil,
        bundle_install: false
      }.freeze

      # Maps option keys to their Bundler settings keys.
      #
      # @return [Hash{Symbol => String}]
      KEY_MAP = {
        coc: 'gem.coc',
        changelog: 'gem.changelog',
        ext: 'gem.ext',
        git: 'gem.git',
        github_username: 'gem.github_username',
        mit: 'gem.mit',
        test: 'gem.test',
        ci: 'gem.ci',
        linter: 'gem.linter'
      }.freeze

      # @param settings [#[], nil] Bundler settings object (or nil to auto-detect)
      def initialize(settings: UNSET)
        @settings = settings.equal?(UNSET) ? default_settings : settings
      end

      # Returns a hash of default values derived from Bundler settings.
      #
      # @return [Hash{Symbol => Object}]
      def detect
        defaults = FALLBACKS.dup
        return defaults unless @settings

        KEY_MAP.each do |option_key, bundler_key|
          value = normalize(@settings[bundler_key])
          defaults[option_key] = value unless value.nil?
        end
        defaults
      rescue StandardError
        FALLBACKS.dup
      end

      private

      # @return [Bundler::Settings, nil]
      def default_settings
        require 'bundler'
        ::Bundler.settings
      rescue LoadError, StandardError
        nil
      end

      # @param value [String, Object, nil]
      # @return [Boolean, String, nil]
      def normalize(value)
        case value
        when 'true'
          true
        when 'false'
          false
        else
          value
        end
      end
    end
  end
end
