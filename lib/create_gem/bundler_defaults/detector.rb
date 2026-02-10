# frozen_string_literal: true

module CreateGem
  module BundlerDefaults
    class Detector
      UNSET = Object.new.freeze

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

      def initialize(settings: UNSET)
        @settings = settings.equal?(UNSET) ? default_settings : settings
      end

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

      def default_settings
        return nil unless defined?(::Bundler)

        ::Bundler.settings
      end

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
