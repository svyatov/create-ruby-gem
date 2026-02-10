# frozen_string_literal: true

require 'optparse'

module CreateGem
  # Main entry point that orchestrates the entire create-gem flow.
  #
  # Parses CLI flags, detects runtime versions, runs the interactive wizard
  # (or loads a preset), builds the +bundle gem+ command, and executes it.
  # All collaborators are injected via constructor for testability.
  #
  # @example Run from the command line
  #   CreateGem::CLI.start(ARGV)
  class CLI
    # Constructs and runs a CLI instance with the given arguments.
    #
    # @param argv [Array<String>] command-line arguments
    # @param out [IO] standard output stream
    # @param err [IO] standard error stream
    # @param store [Config::Store] configuration persistence
    # @param detector [Detection::Runtime] runtime version detector
    # @param runner [Runner, nil] command runner (built from +out+ if nil)
    # @param prompter [UI::Prompter, nil] user interaction handler
    # @param palette [UI::Palette, nil] color palette for terminal output
    # @return [Integer] exit code (0 on success, non-zero on failure)
    def self.start(
      argv = ARGV,
      out: $stdout,
      err: $stderr,
      store: Config::Store.new,
      detector: Detection::Runtime.new,
      runner: nil,
      prompter: nil,
      palette: nil
    )
      instance = new(
        argv: argv,
        out: out,
        err: err,
        store: store,
        detector: detector,
        runner: runner || Runner.new(out: out),
        prompter: prompter,
        palette: palette
      )
      instance.run
    end

    # @param argv [Array<String>] command-line arguments
    # @param out [IO] standard output stream
    # @param err [IO] standard error stream
    # @param store [Config::Store] configuration persistence
    # @param detector [Detection::Runtime] runtime version detector
    # @param runner [Runner] command runner
    # @param prompter [UI::Prompter, nil] user interaction handler
    # @param palette [UI::Palette, nil] color palette for terminal output
    def initialize(argv:, out:, err:, store:, detector:, runner:, prompter:, palette:)
      @argv = argv.dup
      @out = out
      @err = err
      @store = store
      @detector = detector
      @runner = runner
      @prompter = prompter
      @palette = palette || UI::Palette.new
      @options = {}
    end

    # Runs the CLI: parses flags, dispatches to the appropriate action,
    # and returns an exit code.
    #
    # @return [Integer] exit code (0 success, 1 error, 130 interrupt)
    def run
      parse_options!

      validate_top_level_flags!

      return print_version if @options[:version]
      return doctor if @options[:doctor]
      return list_presets if @options[:list_presets]
      return show_preset if @options[:show_preset]
      return delete_preset if @options[:delete_preset]

      runtime_versions = resolved_runtime_versions
      compatibility_entry = Compatibility::Matrix.for(runtime_versions.bundler)
      builder = CommandBuilder.new(compatibility_entry: compatibility_entry)
      bundler_defaults = Detection::BundlerDefaults.new.detect
      last_used = symbolize_keys(@store.last_used)

      gem_name = resolve_gem_name!
      selected_options =
        if @options[:preset]
          load_preset_options!
        else
          run_interactive_wizard!(
            gem_name: gem_name,
            builder: builder,
            compatibility_entry: compatibility_entry,
            last_used: last_used,
            runtime_versions: runtime_versions,
            bundler_defaults: bundler_defaults
          )
        end

      Options::Validator.new(compatibility_entry).validate!(gem_name: gem_name, options: selected_options)
      command = builder.build(gem_name: gem_name, options: selected_options)
      @runner.run!(command, dry_run: @options[:dry_run])
      @store.save_last_used(selected_options)
      save_preset_if_requested(selected_options)
      0
    rescue OptionParser::ParseError, Error => e
      @err.puts(e.message)
      1
    rescue Interrupt
      @err.puts(::CLI::UI.fmt('{{green:See ya!}}'))
      130
    end

    private

    attr_reader :palette

    # @return [void]
    def parse_options!
      OptionParser.new do |parser|
        parser.on('--preset NAME') { |value| @options[:preset] = value }
        parser.on('--save-preset NAME') { |value| @options[:save_preset] = value }
        parser.on('--list-presets') { @options[:list_presets] = true }
        parser.on('--show-preset NAME') { |value| @options[:show_preset] = value }
        parser.on('--delete-preset NAME') { |value| @options[:delete_preset] = value }
        parser.on('--doctor') { @options[:doctor] = true }
        parser.on('--version') { @options[:version] = true }
        parser.on('--dry-run') { @options[:dry_run] = true }
        parser.on('--bundler-version VERSION') { |value| @options[:bundler_version] = value }
      end.parse!(@argv)
    end

    # @raise [ValidationError] if conflicting flags are combined
    # @return [void]
    def validate_top_level_flags!
      conflicting_create_action = @options[:preset] || @options[:save_preset] || !@argv.empty?
      query_action = @options[:list_presets] || @options[:show_preset]
      if query_action && (@options[:delete_preset] || conflicting_create_action)
        raise ValidationError, 'Preset query options cannot be combined with other actions'
      end

      if @options[:delete_preset] && conflicting_create_action
        raise ValidationError, '--delete-preset cannot be combined with create actions'
      end

      if @options[:doctor] && (query_action || @options[:delete_preset] || conflicting_create_action)
        raise ValidationError, '--doctor cannot be combined with other actions'
      end

      conflicting_action = @options[:doctor] || query_action
      conflicting_action ||= @options[:delete_preset]
      conflicting_action ||= conflicting_create_action
      return unless @options[:version] && conflicting_action

      raise ValidationError, '--version cannot be combined with other actions'
    end

    # @return [Integer] exit code
    def print_version
      @out.puts(VERSION)
      0
    end

    # Prints runtime version info and supported options.
    #
    # @return [Integer] exit code
    def doctor
      runtime_versions = resolved_runtime_versions
      @out.puts("ruby: #{runtime_versions.ruby}")
      @out.puts("rubygems: #{runtime_versions.rubygems}")
      @out.puts("bundler: #{runtime_versions.bundler}")
      entry = Compatibility::Matrix.for(runtime_versions.bundler)
      options = Options::Catalog::ORDER.select { |key| entry.supports_option?(key) }
      @out.puts("supported options: #{options.join(', ')}")
      0
    rescue UnsupportedBundlerVersionError => e
      @err.puts(e.message)
      1
    end

    # @return [Integer] exit code
    def list_presets
      @store.preset_names.each { |name| @out.puts(name) }
      0
    end

    # @return [Integer] exit code
    # @raise [ValidationError] if the preset does not exist
    def show_preset
      preset = @store.preset(@options[:show_preset])
      raise ValidationError, "Preset not found: #{@options[:show_preset]}" unless preset

      @out.puts(@options[:show_preset])
      preset.sort.each { |key, value| @out.puts("  #{key}: #{value.inspect}") }
      0
    end

    # @return [Integer] exit code
    def delete_preset
      @store.delete_preset(@options[:delete_preset])
      0
    end

    # @return [String] gem name from argv or interactive prompt
    # @raise [ValidationError] if gem name is required but missing
    def resolve_gem_name!
      gem_name = @argv.shift
      return gem_name if gem_name && !gem_name.empty?

      raise ValidationError, 'Gem name is required when --preset is provided' if @options[:preset]

      prompter.text('Gem name:', allow_empty: false)
    end

    # @return [Hash{Symbol => Object}] preset options
    # @raise [ValidationError] if the preset does not exist
    def load_preset_options!
      preset = @store.preset(@options[:preset])
      raise ValidationError, "Preset not found: #{@options[:preset]}" unless preset

      symbolize_keys(preset)
    end

    # Runs the interactive wizard loop with summary + edit-again flow.
    #
    # @param gem_name [String]
    # @param builder [CommandBuilder]
    # @param compatibility_entry [Compatibility::Matrix::Entry]
    # @param last_used [Hash{Symbol => Object}]
    # @param runtime_versions [Detection::RuntimeInfo]
    # @param bundler_defaults [Hash{Symbol => Object}]
    # @return [Hash{Symbol => Object}] selected options
    def run_interactive_wizard!(
      gem_name:,
      builder:,
      compatibility_entry:,
      last_used:,
      runtime_versions:,
      bundler_defaults:
    )
      defaults = last_used
      prompter.frame('Controls') do
        prompter.say("Press #{palette.color(:control_back, 'Ctrl+B')} to go back one step.")
        prompter.say("Press #{palette.color(:control_exit, 'Ctrl+C')} to exit.")
      end
      loop do
        selected_options = Wizard.new(
          compatibility_entry: compatibility_entry,
          defaults: defaults,
          bundler_defaults: bundler_defaults,
          prompter: prompter
        ).run

        command = builder.build(gem_name: gem_name, options: selected_options)
        show_summary(
          command: command,
          runtime_versions: runtime_versions
        )
        action = prompter.choose('Next step', options: ['create', 'edit again'], default: 'create')
        return selected_options if action == 'create'

        defaults = selected_options
      end
    end

    # @param command [Array<String>]
    # @param runtime_versions [Detection::RuntimeInfo]
    # @return [void]
    def show_summary(command:, runtime_versions:)
      command_name = command.first(2).join(' ')
      gem_name = command[2].to_s
      args = command[3..] || []

      prompter.frame('create-gem summary') do
        runtime_line = "#{palette.color(:summary_label, 'Runtime:')} "
        runtime_line += format_runtime_versions(runtime_versions)
        prompter.say(runtime_line)
        command_line = "#{palette.color(:command_base, command_name)} "
        command_line += palette.color(:command_gem, gem_name)
        command_line += " #{format_args(args)}" unless args.empty?
        prompter.say("#{palette.color(:summary_label, 'Command:')} #{command_line}")
      end
    end

    # @param runtime_versions [Detection::RuntimeInfo]
    # @return [String]
    def format_runtime_versions(runtime_versions)
      [
        ['ruby', runtime_versions.ruby],
        ['rubygems', runtime_versions.rubygems],
        ['bundler', runtime_versions.bundler]
      ].map do |name, version|
        "#{palette.color(:runtime_name, name)} #{palette.color(:runtime_value, version.to_s)}"
      end.join(', ')
    end

    # @param args [Array<String>]
    # @return [String]
    def format_args(args)
      args.map { |argument| format_argument(argument) }.join(' ')
    end

    # @param argument [String]
    # @return [String]
    def format_argument(argument)
      return palette.color(:arg_value, argument) unless argument.start_with?('--')
      return palette.color(:arg_name, argument) unless argument.include?('=')

      name, value = argument.split('=', 2)
      "#{palette.color(:arg_name, name)}#{palette.color(:arg_eq, '=')}#{palette.color(:arg_value, value)}"
    end

    # @param selected_options [Hash{Symbol => Object}]
    # @return [void]
    def save_preset_if_requested(selected_options)
      if @options[:save_preset]
        @store.save_preset(@options[:save_preset], selected_options)
        return
      end

      return if @options[:preset]
      return unless prompter.confirm('Save these options as a preset?', default: false)

      preset_name = prompter.text('Preset name:', allow_empty: false)
      @store.save_preset(preset_name, selected_options)
    end

    # @param hash [Hash{String => Object}]
    # @return [Hash{Symbol => Object}]
    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end

    # @return [Detection::RuntimeInfo]
    def resolved_runtime_versions
      if @options[:bundler_version]
        return Detection::RuntimeInfo.new(
          ruby: Gem::Version.new(RUBY_VERSION),
          rubygems: Gem::Version.new(Gem::VERSION),
          bundler: Gem::Version.new(@options[:bundler_version])
        )
      end

      @detector.detect!
    end

    # @return [UI::Prompter]
    def prompter
      @prompter ||= begin
        UI::Prompter.setup!
        UI::Prompter.new(out: @out)
      end
    end
  end
end
