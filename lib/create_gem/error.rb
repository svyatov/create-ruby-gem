# frozen_string_literal: true

module CreateGem
  class Error < StandardError; end
  class ConfigError < Error; end
  class ValidationError < Error; end
  class UnsupportedBundlerVersionError < Error; end
end
