# frozen_string_literal: true

module CreateRubyGem
  # Base error for all create-ruby-gem failures.
  class Error < StandardError; end

  # Raised when the config file is corrupt or unreadable.
  class ConfigError < Error; end

  # Raised when CLI flags or option values are invalid.
  class ValidationError < Error; end

  # Raised when the detected Bundler version is outside all known ranges.
  class UnsupportedBundlerVersionError < Error; end
end
