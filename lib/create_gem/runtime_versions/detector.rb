# frozen_string_literal: true

module CreateGem
  module RuntimeVersions
    # Holds detected Ruby, RubyGems, and Bundler versions.
    #
    # @!attribute [r] ruby
    #   @return [Gem::Version]
    # @!attribute [r] rubygems
    #   @return [Gem::Version]
    # @!attribute [r] bundler
    #   @return [Gem::Version]
    Versions = Struct.new(:ruby, :rubygems, :bundler, keyword_init: true)

    # Detects the current Ruby, RubyGems, and Bundler versions.
    class Detector
      # @param bundler_detector [BundlerVersion::Detector]
      def initialize(bundler_detector: BundlerVersion::Detector.new)
        @bundler_detector = bundler_detector
      end

      # @return [Versions]
      # @raise [UnsupportedBundlerVersionError] if Bundler cannot be detected
      def detect!
        Versions.new(
          ruby: Gem::Version.new(RUBY_VERSION),
          rubygems: Gem::Version.new(Gem::VERSION),
          bundler: @bundler_detector.detect!
        )
      end
    end
  end
end
