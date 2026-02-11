# frozen_string_literal: true

module CreateRubyGem
  module Detection
    # Detects the installed Bundler version by running +bundle --version+.
    class BundlerVersion
      # @return [Regexp] pattern to extract a version string
      VERSION_PATTERN = /(\d+\.\d+\.\d+)/

      # @param bundle_command [String] path or name of the bundle executable
      def initialize(bundle_command: 'bundle')
        @bundle_command = bundle_command
      end

      # Runs +bundle --version+ and parses the result.
      #
      # @return [Gem::Version]
      # @raise [UnsupportedBundlerVersionError] if the version cannot be parsed
      #   or the executable is not found
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
