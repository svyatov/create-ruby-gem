# frozen_string_literal: true

module CreateGem
  module RuntimeVersions
    Versions = Struct.new(:ruby, :rubygems, :bundler, keyword_init: true)

    class Detector
      def initialize(bundler_detector: BundlerVersion::Detector.new)
        @bundler_detector = bundler_detector
      end

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
