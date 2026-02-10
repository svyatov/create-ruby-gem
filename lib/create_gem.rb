# frozen_string_literal: true

require_relative 'create_gem/version'
require_relative 'create_gem/error'
require_relative 'create_gem/detection/bundler_version'
require_relative 'create_gem/detection/bundler_defaults'
require_relative 'create_gem/detection/runtime'
require_relative 'create_gem/options/catalog'
require_relative 'create_gem/compatibility/matrix'
require_relative 'create_gem/options/validator'
require_relative 'create_gem/command_builder'
require_relative 'create_gem/config/store'
require_relative 'create_gem/runner'
require_relative 'create_gem/ui/palette'
require_relative 'create_gem/ui/prompter'
require_relative 'create_gem/wizard'
require_relative 'create_gem/cli'

# Interactive TUI wizard for +bundle gem+.
#
# Detects the user's Ruby/Bundler versions, shows only compatible options
# via a static compatibility matrix, and builds the correct +bundle gem+
# command. Config (presets, last-used options) is stored in
# +~/.config/create-gem/config.yml+.
#
# @see CreateGem::CLI Entry point
# @see CreateGem::Compatibility::Matrix Bundler version compatibility
module CreateGem
end
