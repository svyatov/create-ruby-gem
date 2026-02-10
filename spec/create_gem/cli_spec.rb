# frozen_string_literal: true

require 'spec_helper'

class CLIFakePrompter
  attr_reader :messages

  def initialize(choices: [], texts: [], confirms: [])
    @choices = choices
    @texts = texts
    @confirms = confirms
    @messages = []
  end

  def choose(_question, options:, default: nil)
    value = @choices.shift
    value = default if value.nil?
    value = options.first if value.nil?
    raise "invalid choice #{value.inspect}" unless options.include?(value)

    value
  end

  def text(_question, default: nil, allow_empty: true)
    value = @texts.shift
    value = default if value.nil?
    value = '' if value.nil? && allow_empty
    value
  end

  def confirm(_question, default: true)
    value = @confirms.shift
    value.nil? ? default : value
  end

  def frame(_title)
    yield
  end

  def say(message)
    @messages << message
  end
end

RSpec.describe CreateGem::CLI do
  it 'lists presets' do
    out = StringIO.new
    store = instance_double(CreateGem::Config::Store, preset_names: %w[fast full])
    detector = instance_double(CreateGem::Detection::Runtime)
    runner = instance_double(CreateGem::Runner)

    status = described_class.start(
      ['--list-presets'],
      out: out,
      err: StringIO.new,
      store: store,
      detector: detector,
      runner: runner,
      prompter: instance_double(CreateGem::UI::Prompter)
    )

    expect(status).to eq(0)
    expect(out.string).to eq("fast\nfull\n")
  end

  it 'runs with preset in dry-run mode' do
    store = instance_double(CreateGem::Config::Store)
    allow(store).to receive(:last_used).and_return({})
    allow(store).to receive(:preset).with('fast').and_return({ 'test' => 'rspec', 'ci' => 'github' })
    allow(store).to receive(:save_last_used)
    allow(store).to receive(:save_preset)
    versions = CreateGem::Detection::RuntimeInfo.new(
      ruby: Gem::Version.new(RUBY_VERSION),
      rubygems: Gem::Version.new(Gem::VERSION),
      bundler: Gem::Version.new('4.0.4')
    )
    detector = instance_double(CreateGem::Detection::Runtime, detect!: versions)
    runner = instance_double(CreateGem::Runner)

    expect(runner).to receive(:run!).with(
      ['bundle', 'gem', 'my_gem', '--test=rspec', '--ci=github'],
      dry_run: true
    )

    status = described_class.start(
      ['my_gem', '--preset', 'fast', '--dry-run'],
      out: StringIO.new,
      err: StringIO.new,
      store: store,
      detector: detector,
      runner: runner,
      prompter: instance_double(CreateGem::UI::Prompter)
    )

    expect(status).to eq(0)
  end

  it 'returns error when preset is missing' do
    err = StringIO.new
    store = instance_double(CreateGem::Config::Store, preset: nil, last_used: {})
    versions = CreateGem::Detection::RuntimeInfo.new(
      ruby: Gem::Version.new(RUBY_VERSION),
      rubygems: Gem::Version.new(Gem::VERSION),
      bundler: Gem::Version.new('4.0.4')
    )

    status = described_class.start(
      ['my_gem', '--preset', 'missing'],
      out: StringIO.new,
      err: err,
      store: store,
      detector: instance_double(CreateGem::Detection::Runtime, detect!: versions),
      runner: instance_double(CreateGem::Runner),
      prompter: instance_double(CreateGem::UI::Prompter)
    )

    expect(status).to eq(1)
    expect(err.string).to include('Preset not found')
  end

  it 'runs interactive flow using defaults' do
    store = instance_double(CreateGem::Config::Store)
    allow(store).to receive(:last_used).and_return({})
    allow(store).to receive(:save_last_used)
    allow(store).to receive(:save_preset)
    prompter = CLIFakePrompter.new
    runner = instance_double(CreateGem::Runner)
    expect(runner).to receive(:run!).with(
      satisfy { |command| command.first(3) == %w[bundle gem demo_gem] },
      dry_run: true
    )

    status = described_class.start(
      ['demo_gem', '--dry-run', '--bundler-version', '4.0.4'],
      out: StringIO.new,
      err: StringIO.new,
      store: store,
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: runner,
      prompter: prompter
    )

    expect(status).to eq(0)
    expect(prompter.messages.any? { |message| message.include?('Runtime:') }).to be(true)
  end

  it 'prints doctor output' do
    out = StringIO.new
    versions = CreateGem::Detection::RuntimeInfo.new(
      ruby: Gem::Version.new('4.0.1'),
      rubygems: Gem::Version.new('4.0.4'),
      bundler: Gem::Version.new('4.0.4')
    )
    detector = instance_double(CreateGem::Detection::Runtime, detect!: versions)

    status = described_class.start(
      ['--doctor'],
      out: out,
      err: StringIO.new,
      store: instance_double(CreateGem::Config::Store),
      detector: detector,
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(0)
    expect(out.string).to include('ruby: 4.0.1')
    expect(out.string).to include('rubygems: 4.0.4')
    expect(out.string).to include('bundler: 4.0.4')
    expect(out.string).to include('supported options:')
  end

  it 'rejects conflicting top-level actions' do
    err = StringIO.new
    status = described_class.start(
      ['demo_gem', '--list-presets'],
      out: StringIO.new,
      err: err,
      store: instance_double(CreateGem::Config::Store),
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(1)
    expect(err.string).to include('Preset query options cannot be combined')
  end

  it 'prints version' do
    out = StringIO.new
    status = described_class.start(
      ['--version'],
      out: out,
      err: StringIO.new,
      store: instance_double(CreateGem::Config::Store),
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(0)
    expect(out.string).to eq("#{CreateGem::VERSION}\n")
  end

  it 'rejects doctor with create args' do
    err = StringIO.new
    status = described_class.start(
      ['demo_gem', '--doctor'],
      out: StringIO.new,
      err: err,
      store: instance_double(CreateGem::Config::Store),
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(1)
    expect(err.string).to include('--doctor cannot be combined')
  end

  it 'shows preset values' do
    out = StringIO.new
    store = instance_double(CreateGem::Config::Store, preset: { 'ci' => 'github', 'test' => 'rspec' })

    status = described_class.start(
      ['--show-preset', 'fast'],
      out: out,
      err: StringIO.new,
      store: store,
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(0)
    expect(out.string).to include('fast')
    expect(out.string).to include('ci: "github"')
    expect(out.string).to include('test: "rspec"')
  end

  it 'returns 130 on interrupt with user-friendly abort line' do
    store = instance_double(CreateGem::Config::Store, last_used: {})
    runner = instance_double(CreateGem::Runner)
    prompter = CLIFakePrompter.new
    allow(prompter).to receive(:choose).and_raise(Interrupt)
    versions = CreateGem::Detection::RuntimeInfo.new(
      ruby: Gem::Version.new(RUBY_VERSION),
      rubygems: Gem::Version.new(Gem::VERSION),
      bundler: Gem::Version.new('4.0.4')
    )

    err = StringIO.new
    status = described_class.start(
      ['demo_gem'],
      out: StringIO.new,
      err: err,
      store: store,
      detector: instance_double(CreateGem::Detection::Runtime, detect!: versions),
      runner: runner,
      prompter: prompter
    )

    expect(status).to eq(130)
    expect(err.string).to include('See ya!')
  end

  it 'delegates --delete-preset to store' do
    store = instance_double(CreateGem::Config::Store)
    expect(store).to receive(:delete_preset).with('old')

    status = described_class.start(
      ['--delete-preset', 'old'],
      out: StringIO.new,
      err: StringIO.new,
      store: store,
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(0)
  end

  it 'returns error for --show-preset with missing preset' do
    err = StringIO.new
    store = instance_double(CreateGem::Config::Store, preset: nil)

    status = described_class.start(
      ['--show-preset', 'missing'],
      out: StringIO.new,
      err: err,
      store: store,
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(1)
    expect(err.string).to include('Preset not found')
  end

  it 'uses --bundler-version to override runtime detection' do
    store = instance_double(CreateGem::Config::Store, last_used: {})
    allow(store).to receive(:save_last_used)
    allow(store).to receive(:save_preset)
    runner = instance_double(CreateGem::Runner)
    expect(runner).to receive(:run!).with(
      satisfy { |cmd| cmd.first(3) == %w[bundle gem my_gem] },
      dry_run: true
    )
    detector = instance_double(CreateGem::Detection::Runtime)

    status = described_class.start(
      ['my_gem', '--dry-run', '--bundler-version', '2.5.0'],
      out: StringIO.new,
      err: StringIO.new,
      store: store,
      detector: detector,
      runner: runner,
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(0)
    expect(detector).not_to have_received(:detect!) if detector.respond_to?(:detect!)
  end

  it 'rejects --version combined with --doctor' do
    err = StringIO.new
    status = described_class.start(
      ['--version', '--doctor'],
      out: StringIO.new,
      err: err,
      store: instance_double(CreateGem::Config::Store),
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(1)
    expect(err.string).to include('--version cannot be combined')
  end

  it 'prompts for gem name when no args and no preset' do
    store = instance_double(CreateGem::Config::Store, last_used: {})
    allow(store).to receive(:save_last_used)
    allow(store).to receive(:save_preset)
    runner = instance_double(CreateGem::Runner)
    expect(runner).to receive(:run!).with(
      satisfy { |cmd| cmd[2] == 'prompted_gem' },
      dry_run: true
    )
    prompter = CLIFakePrompter.new(texts: ['prompted_gem'])

    status = described_class.start(
      ['--dry-run', '--bundler-version', '4.0.4'],
      out: StringIO.new,
      err: StringIO.new,
      store: store,
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: runner,
      prompter: prompter
    )

    expect(status).to eq(0)
  end

  it 'returns error for missing gem name with --preset' do
    err = StringIO.new
    store = instance_double(CreateGem::Config::Store, last_used: {})
    versions = CreateGem::Detection::RuntimeInfo.new(
      ruby: Gem::Version.new(RUBY_VERSION),
      rubygems: Gem::Version.new(Gem::VERSION),
      bundler: Gem::Version.new('4.0.4')
    )

    status = described_class.start(
      ['--preset', 'fast'],
      out: StringIO.new,
      err: err,
      store: store,
      detector: instance_double(CreateGem::Detection::Runtime, detect!: versions),
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(1)
    expect(err.string).to include('Gem name is required')
  end

  it 'saves preset via --save-preset after run' do
    store = instance_double(CreateGem::Config::Store)
    allow(store).to receive(:last_used).and_return({})
    allow(store).to receive(:preset).with('fast').and_return({ 'test' => 'rspec' })
    allow(store).to receive(:save_last_used)
    expect(store).to receive(:save_preset).with('mypreset', anything)
    runner = instance_double(CreateGem::Runner)
    allow(runner).to receive(:run!)

    status = described_class.start(
      ['my_gem', '--preset', 'fast', '--save-preset', 'mypreset', '--dry-run', '--bundler-version', '4.0.4'],
      out: StringIO.new,
      err: StringIO.new,
      store: store,
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: runner,
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(0)
  end

  it 'rejects --delete-preset combined with create actions' do
    err = StringIO.new
    status = described_class.start(
      ['my_gem', '--delete-preset', 'old'],
      out: StringIO.new,
      err: err,
      store: instance_double(CreateGem::Config::Store),
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(1)
    expect(err.string).to include('--delete-preset cannot be combined')
  end

  it 'doctor returns error on unsupported bundler version' do
    err = StringIO.new
    detector = instance_double(CreateGem::Detection::Runtime)
    allow(detector).to receive(:detect!).and_raise(
      CreateGem::UnsupportedBundlerVersionError, 'Unsupported bundler version: 1.0'
    )

    status = described_class.start(
      ['--doctor'],
      out: StringIO.new,
      err: err,
      store: instance_double(CreateGem::Config::Store),
      detector: detector,
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(1)
    expect(err.string).to include('Unsupported bundler version')
  end

  it 'returns error for unknown flags' do
    err = StringIO.new

    status = described_class.start(
      ['--unknown-flag'],
      out: StringIO.new,
      err: err,
      store: instance_double(CreateGem::Config::Store),
      detector: instance_double(CreateGem::Detection::Runtime),
      runner: instance_double(CreateGem::Runner),
      prompter: CLIFakePrompter.new
    )

    expect(status).to eq(1)
    expect(err.string).to include('invalid option')
  end
end
