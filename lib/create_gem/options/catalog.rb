# frozen_string_literal: true

module CreateGem
  module Options
    # Registry of every +bundle gem+ option create-gem knows about.
    #
    # Each entry in {DEFINITIONS} describes the option's type and CLI flags.
    # {ORDER} controls the sequence in which the wizard presents options.
    #
    # @see Options::Validator
    # @see Wizard::Session
    module Catalog
      # Option definitions keyed by symbolic name.
      #
      # Each value is a Hash with +:type+ and the relevant flag keys
      # (+:on+/+:off+ for toggles, +:flag+ for enums/strings, etc.).
      #
      # @return [Hash{Symbol => Hash}]
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

      # Wizard step order — matches the sequence users see.
      #
      # @return [Array<Symbol>]
      ORDER = DEFINITIONS.keys.freeze

      # Fetches the definition for a given option key.
      #
      # @param key [Symbol, String]
      # @return [Hash] the option definition
      # @raise [KeyError] if the key is unknown
      def self.fetch(key)
        DEFINITIONS.fetch(key.to_sym)
      end
    end
  end
end
