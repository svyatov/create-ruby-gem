# frozen_string_literal: true

require_relative 'create_gem/version'
require_relative 'create_gem/error'
require_relative 'create_gem/bundler_version/detector'
require_relative 'create_gem/bundler_defaults/detector'
require_relative 'create_gem/runtime_versions/detector'
require_relative 'create_gem/options/catalog'
require_relative 'create_gem/compatibility/matrix'
require_relative 'create_gem/options/validator'
require_relative 'create_gem/command/builder'
require_relative 'create_gem/config/store'
require_relative 'create_gem/runner'
require_relative 'create_gem/ui/palette'
require_relative 'create_gem/ui/prompter'
require_relative 'create_gem/wizard/session'
require_relative 'create_gem/cli'

module CreateGem
end
