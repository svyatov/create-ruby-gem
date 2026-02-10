# frozen_string_literal: true

module CreateGem
  # Step-by-step interactive prompt loop for choosing +bundle gem+ options.
  #
  # Walks through each supported option in {Options::Catalog::ORDER},
  # presenting only the options supported by the detected Bundler version.
  # Supports back-navigation via +Ctrl+B+.
  #
  # @see CLI#run_interactive_wizard!
  class Wizard
    # Sentinel returned by the prompter when the user presses Ctrl+B.
    BACK = Object.new.freeze

    # Sentinel indicating the user wants Bundler's built-in default.
    BUNDLER_DEFAULT = Object.new.freeze

    # Human-readable labels for each option key.
    #
    # @return [Hash{Symbol => String}]
    LABELS = {
      exe: 'Create executable',
      coc: 'Add CODE_OF_CONDUCT.md',
      changelog: 'Add CHANGELOG.md',
      ext: 'Native extension',
      git: 'Initialize git',
      github_username: 'GitHub username',
      mit: 'Include MIT license',
      test: 'Test framework',
      ci: 'CI provider',
      linter: 'Linter',
      edit: 'Editor command',
      bundle_install: 'Run bundle install'
    }.freeze

    # Short explanations shown below each wizard step.
    #
    # @return [Hash{Symbol => String}]
    HELP_TEXT = {
      exe: 'Adds an executable file in exe/ so users can run your gem as a command.',
      coc: 'Adds a code of conduct template for contributors.',
      changelog: 'Adds CHANGELOG.md to track release notes.',
      ext: 'Sets up native extension scaffolding for C, Go, or Rust.',
      git: 'Initializes a git repository for the new gem.',
      github_username: 'Used in links and metadata for your GitHub account.',
      mit: 'Adds the MIT license file.',
      test: 'Chooses which test framework files to generate.',
      ci: 'Chooses CI pipeline config to include.',
      linter: 'Chooses linting setup for style and quality checks.',
      edit: 'Sets your preferred command for opening files.',
      bundle_install: 'Runs bundle install after generating the gem.'
    }.freeze

    # Per-choice hints displayed next to enum/string choices.
    #
    # @return [Hash{Symbol => Hash{String => String}}]
    CHOICE_HELP = {
      ext: {
        'c' => 'classic native extension path',
        'go' => 'Go-based extension via FFI/tooling',
        'rust' => 'Rust extension path',
        'none' => 'no native extension'
      },
      test: {
        'minitest' => 'small built-in Ruby test style',
        'rspec' => 'popular behavior-style testing',
        'test-unit' => 'xUnit-style test framework',
        'none' => 'no test framework files'
      },
      ci: {
        'circle' => 'CircleCI config',
        'github' => 'GitHub Actions workflow',
        'gitlab' => 'GitLab CI pipeline',
        'none' => 'no CI config'
      },
      linter: {
        'rubocop' => 'full-featured Ruby linting',
        'standard' => 'zero-config style linting',
        'none' => 'no linter config'
      },
      github_username: {
        'set' => 'enter a value now',
        'none' => 'leave unset'
      },
      edit: {
        'set' => 'enter a value now',
        'none' => 'leave unset'
      }
    }.freeze

    # @param compatibility_entry [Compatibility::Matrix::Entry]
    # @param defaults [Hash{Symbol => Object}] initial default values (e.g. last-used)
    # @param prompter [UI::Prompter]
    # @param bundler_defaults [Hash{Symbol => Object}] Bundler's own defaults
    def initialize(compatibility_entry:, defaults:, prompter:, bundler_defaults: {})
      @compatibility_entry = compatibility_entry
      @bundler_defaults = symbolize_keys(bundler_defaults)
      @prompter = prompter
      @values = sanitize_defaults(defaults)
    end

    # Runs the wizard and returns the selected options.
    #
    # @return [Hash{Symbol => Object}]
    def run
      keys = Options::Catalog::ORDER.select { |key| @compatibility_entry.supports_option?(key) }
      index = 0
      while index < keys.length
        key = keys[index]
        answer = ask_for(key, index:, total: keys.length)
        case answer
        when BACK
          index -= 1 if index.positive?
        else
          assign_value(key, answer)
          index += 1
        end
      end
      @values.dup
    end

    private

    # @param key [Symbol]
    # @param index [Integer]
    # @param total [Integer]
    # @return [Object] user answer or {BACK}
    def ask_for(key, index:, total:)
      definition = Options::Catalog.fetch(key)
      label = LABELS.fetch(key)
      question = render_question(index: index, total: total, key: key, label: label)
      case definition[:type]
      when :toggle
        ask_toggle(question, key)
      when :flag
        ask_flag(question, key)
      when :enum
        ask_enum(question, key, definition)
      when :string
        ask_string(question, key)
      else
        raise Error, "Unknown option type for #{key}"
      end
    end

    # @param question [String]
    # @param key [Symbol]
    # @return [true, false, nil, String]
    def ask_toggle(question, key)
      choices = %w[yes no]
      current = @values[key]
      default_choice = toggle_default_choice(current, key)
      answer = choose_with_default_marker(question, key:, choices:, default_choice:)
      return BACK if answer == BACK
      return true if answer == 'yes'
      return false if answer == 'no'

      nil
    end

    # @param question [String]
    # @param key [Symbol]
    # @return [true, String, nil]
    def ask_flag(question, key)
      choices = %w[yes no]
      current = @values[key]
      default_choice = current == true ? 'yes' : flag_default_choice(key)
      answer = choose_with_default_marker(question, key:, choices:, default_choice:)
      return BACK if answer == BACK
      return true if answer == 'yes'
      return BUNDLER_DEFAULT if answer == 'no'

      nil
    end

    # @param question [String]
    # @param key [Symbol]
    # @param definition [Hash]
    # @return [String, false, String]
    def ask_enum(question, key, definition)
      choices = @compatibility_entry.allowed_values(key).dup
      choices << 'none' if definition[:none]
      current = @values[key]
      default_choice = enum_default_choice(key, current, choices)
      answer = choose_with_default_marker(question, key:, choices:, default_choice:)
      return BACK if answer == BACK
      return false if answer == 'none'

      answer
    end

    # @param question [String]
    # @param key [Symbol]
    # @return [String, nil, String]
    def ask_string(question, key)
      has_current = @values[key].is_a?(String) && !@values[key].empty?
      choices =
        if has_current
          %w[keep set]
        else
          %w[set none]
        end
      default_choice = has_current ? 'keep' : 'none'
      answer = choose_with_default_marker(question, key:, choices:, default_choice:)
      return BACK if answer == BACK
      return BUNDLER_DEFAULT if answer == 'none'
      return @values[key] if answer == 'keep'

      default_value = key == :github_username ? nil : @values[key]
      allow_empty = key != :github_username
      value = @prompter.text("#{LABELS.fetch(key)}:", default: default_value, allow_empty: allow_empty)
      value.empty? ? nil : value
    end

    # @param key [Symbol]
    # @param value [Object]
    # @return [void]
    def assign_value(key, value)
      if value.nil? || value == BUNDLER_DEFAULT
        @values.delete(key)
      else
        @values[key] = value
      end
    end

    # @param hash [Hash]
    # @return [Hash{Symbol => Object}]
    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end

    # Filters defaults to only supported options and removes false flags.
    #
    # @param hash [Hash]
    # @return [Hash{Symbol => Object}]
    def sanitize_defaults(hash)
      symbolize_keys(hash)
        .select { |key, _| @compatibility_entry.supports_option?(key) }
        .each_with_object({}) do |(key, value), acc|
          definition = Options::Catalog.fetch(key)
          acc[key] = value unless definition[:type] == :flag && value == false
        end
    end

    # @param current [Object]
    # @param key [Symbol]
    # @return [String]
    def toggle_default_choice(current, key)
      return 'yes' if current == true
      return 'no' if current == false

      @bundler_defaults[key] == true ? 'yes' : 'no'
    end

    # @param key [Symbol]
    # @return [String]
    def flag_default_choice(key)
      @bundler_defaults[key] == true ? 'yes' : 'no'
    end

    # @param key [Symbol]
    # @param current [Object]
    # @param choices [Array<String>]
    # @return [String]
    def enum_default_choice(key, current, choices)
      return 'none' if current == false && choices.include?('none')
      return current if current.is_a?(String) && choices.include?(current)

      bundler_default = @bundler_defaults[key]
      return 'none' if bundler_default == false && choices.include?('none')
      return bundler_default if bundler_default.is_a?(String) && choices.include?(bundler_default)

      choices.first
    end

    # Presents a choice list with the default marked and reordered first.
    #
    # @param question [String]
    # @param key [Symbol]
    # @param choices [Array<String>]
    # @param default_choice [String]
    # @return [String] the raw choice value, or {BACK}
    def choose_with_default_marker(question, key:, choices:, default_choice:)
      selected_default = choices.include?(default_choice) ? default_choice : choices.first
      ordered_choices = reorder_default_first(choices, selected_default)
      rendered_pairs = ordered_choices.map do |choice|
        [render_choice_label(key, choice, default_choice: selected_default), choice]
      end
      rendered = rendered_pairs.map(&:first)
      answer = @prompter.choose(question, options: rendered, default: rendered.first)
      return BACK if answer == BACK

      rendered_index = rendered.index(answer)
      return ordered_choices[rendered_index] if rendered_index

      selected_default
    end

    # @param choices [Array<String>]
    # @param default_choice [String]
    # @return [Array<String>]
    def reorder_default_first(choices, default_choice)
      return choices.dup unless choices.include?(default_choice)

      [default_choice] + choices.reject { |choice| choice == default_choice }
    end

    # @param index [Integer]
    # @param total [Integer]
    # @param key [Symbol]
    # @param label [String]
    # @return [String]
    def render_question(index:, total:, key:, label:)
      step = format('%<current>02d/%<total>02d', current: index + 1, total: total)
      "{{cyan:#{step}}} {{bold:#{label}}} - #{HELP_TEXT.fetch(key)}"
    end

    # @param key [Symbol]
    # @param choice [String]
    # @param default_choice [String]
    # @return [String]
    def render_choice_label(key, choice, default_choice:)
      label = choice
      hint = choice_hint(key, choice)
      label = "#{label} - #{hint}" if hint
      label = "#{label} (default)" if choice == default_choice
      label
    end

    # @param key [Symbol]
    # @param choice [String]
    # @return [String, nil]
    def choice_hint(key, choice)
      return "use #{@values[key]}" if choice == 'keep' && @values[key].is_a?(String) && !@values[key].empty?

      CHOICE_HELP.dig(key, choice)
    end
  end
end
