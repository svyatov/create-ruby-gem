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
    detector = instance_double(CreateGem::BundlerVersion::Detector)
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
    detector = instance_double(CreateGem::BundlerVersion::Detector, detect!: Gem::Version.new('4.0.4'))
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

    status = described_class.start(
      ['my_gem', '--preset', 'missing'],
      out: StringIO.new,
      err: err,
      store: store,
      detector: instance_double(CreateGem::BundlerVersion::Detector, detect!: Gem::Version.new('4.0.4')),
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
      detector: instance_double(CreateGem::BundlerVersion::Detector),
      runner: runner,
      prompter: prompter
    )

    expect(status).to eq(0)
    expect(prompter.messages.any? { |message| message.include?('Runtime:') }).to be(true)
  end

  it 'prints doctor output' do
    out = StringIO.new
    versions = CreateGem::RuntimeVersions::Versions.new(
      ruby: Gem::Version.new('4.0.1'),
      rubygems: Gem::Version.new('4.0.4'),
      bundler: Gem::Version.new('4.0.4')
    )
    detector = instance_double(CreateGem::RuntimeVersions::Detector, detect!: versions)

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
      detector: instance_double(CreateGem::RuntimeVersions::Detector),
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
      detector: instance_double(CreateGem::RuntimeVersions::Detector),
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
      detector: instance_double(CreateGem::RuntimeVersions::Detector),
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
      detector: instance_double(CreateGem::RuntimeVersions::Detector),
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

    err = StringIO.new
    status = described_class.start(
      ['demo_gem'],
      out: StringIO.new,
      err: err,
      store: store,
      detector: instance_double(CreateGem::RuntimeVersions::Detector, detect!: Gem::Version.new('4.0.4')),
      runner: runner,
      prompter: prompter
    )

    expect(status).to eq(130)
    expect(err.string).to include('See ya!')
  end
end
