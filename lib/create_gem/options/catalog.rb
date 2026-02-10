# frozen_string_literal: true

module CreateGem
  module Options
    module Catalog
      DEFINITIONS = {
        exe: { type: :toggle, on: '--exe', off: '--no-exe' },
        coc: { type: :toggle, on: '--coc', off: '--no-coc' },
        changelog: { type: :toggle, on: '--changelog', off: '--no-changelog' },
        ext: { type: :enum, flag: '--ext', none: '--no-ext', values: %w[c go rust] },
        git: { type: :flag, on: '--git' },
        github_username: { type: :string, flag: '--github-username' },
        mit: { type: :toggle, on: '--mit', off: '--no-mit' },
        test: { type: :enum, flag: '--test', none: '--no-test', values: %w[minitest rspec test-unit] },
        ci: { type: :enum, flag: '--ci', none: '--no-ci', values: %w[circle github gitlab] },
        linter: { type: :enum, flag: '--linter', none: '--no-linter', values: %w[rubocop standard] },
        edit: { type: :string, flag: '--edit' },
        bundle_install: { type: :toggle, on: '--bundle', off: '--no-bundle' }
      }.freeze

      ORDER = DEFINITIONS.keys.freeze

      def self.fetch(key)
        DEFINITIONS.fetch(key.to_sym)
      end
    end
  end
end
