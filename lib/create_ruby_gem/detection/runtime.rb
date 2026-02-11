# frozen_string_literal: true

module CreateRubyGem
  module Detection
    # Holds detected Ruby, RubyGems, and Bundler versions.
    #
    # @!attribute [r] ruby
    #   @return [Gem::Version]
    # @!attribute [r] rubygems
    #   @return [Gem::Version]
    # @!attribute [r] bundler
    #   @return [Gem::Version]
    RuntimeInfo = Struct.new(:ruby, :rubygems, :bundler, keyword_init: true)

    # Detects the current Ruby, RubyGems, and Bundler versions.
    class Runtime
      # @param bundler_detector [Detection::BundlerVersion]
      def initialize(bundler_detector: BundlerVersion.new)
        @bundler_detector = bundler_detector
      end

      # @return [RuntimeInfo]
      # @raise [UnsupportedBundlerVersionError] if Bundler cannot be detected
      def detect!
        RuntimeInfo.new(
          ruby: Gem::Version.new(RUBY_VERSION),
          rubygems: Gem::Version.new(Gem::VERSION),
          bundler: @bundler_detector.detect!
        )
      end
    end
  end
end
