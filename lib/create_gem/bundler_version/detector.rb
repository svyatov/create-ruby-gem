# frozen_string_literal: true

module CreateGem
  module BundlerVersion
    class Detector
      VERSION_PATTERN = /(\d+\.\d+\.\d+)/

      def initialize(bundle_command: 'bundle')
        @bundle_command = bundle_command
      end

      def detect!
        output = IO.popen([@bundle_command, '--version'], err: %i[child out], &:read)
        version = output[VERSION_PATTERN, 1]
        return Gem::Version.new(version) if version

        raise UnsupportedBundlerVersionError, "Cannot parse bundler version from: #{output.inspect}"
      rescue Errno::ENOENT
        raise UnsupportedBundlerVersionError, "Bundler executable not found: #{@bundle_command}"
      end
    end
  end
end
