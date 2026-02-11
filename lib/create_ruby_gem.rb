# frozen_string_literal: true

require_relative 'create_ruby_gem/version'
require_relative 'create_ruby_gem/error'
require_relative 'create_ruby_gem/detection/bundler_version'
require_relative 'create_ruby_gem/detection/bundler_defaults'
require_relative 'create_ruby_gem/detection/runtime'
require_relative 'create_ruby_gem/options/catalog'
require_relative 'create_ruby_gem/compatibility/matrix'
require_relative 'create_ruby_gem/options/validator'
require_relative 'create_ruby_gem/command_builder'
require_relative 'create_ruby_gem/config/store'
require_relative 'create_ruby_gem/runner'
require_relative 'create_ruby_gem/ui/palette'
require_relative 'create_ruby_gem/ui/prompter'
require_relative 'create_ruby_gem/wizard'
require_relative 'create_ruby_gem/cli'

# Interactive TUI wizard for +bundle gem+.
#
# Detects the user's Ruby/Bundler versions, shows only compatible options
# via a static compatibility matrix, and builds the correct +bundle gem+
# command. Config (presets, last-used options) is stored in
# +~/.config/create-ruby-gem/config.yml+.
#
# @see CreateRubyGem::CLI Entry point
# @see CreateRubyGem::Compatibility::Matrix Bundler version compatibility
module CreateRubyGem
end
