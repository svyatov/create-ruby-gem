# frozen_string_literal: true

require 'spec_helper'

class WizardFakePrompter
  attr_reader :seen_options, :seen_questions

  def initialize(choices:, texts: [])
    @choices = choices
    @texts = texts
    @seen_options = []
    @seen_questions = []
  end

  def choose(question, options:, default: nil)
    @seen_questions << question
    @seen_options << options
    value = @choices.shift || default
    return CreateRubyGem::Wizard::BACK if value == CreateRubyGem::Wizard::BACK

    value ||= options.first
    unless options.include?(value)
      labeled_value = options.find do |option|
        normalized = strip_markup(option).gsub(/\n+/, '').sub(/ \(default\)\z/, '').sub(/ - .+\z/, '')
        normalized == value
      end
      value = labeled_value unless labeled_value.nil?
    end
    raise "invalid choice #{value.inspect}" unless options.include?(value)

    value
  end

  def text(_question, default: nil, allow_empty: true)
    value = @texts.shift
    value = default if value.nil?
    value = '' if value.nil? && allow_empty
    value
  end

  private

  def strip_markup(value)
    value.gsub(/\{\{[^:}]+:/, '').gsub('}}', '')
  end
end

RSpec.describe CreateRubyGem::Wizard do
  it 'supports going back to previous steps' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: {
        exe: nil,
        test: %w[rspec],
        github_username: nil
      }
    )
    prompter = WizardFakePrompter.new(
      choices: ['yes', 'set', CreateRubyGem::Wizard::BACK, 'set', 'rspec'],
      texts: %w[old-user leonid]
    )

    result = described_class.new(compatibility_entry: entry, defaults: {}, prompter: prompter).run

    expect(result).to eq(exe: true, github_username: 'leonid', test: 'rspec')
  end

  it 'keeps existing string value when requested' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: { github_username: nil }
    )
    prompter = WizardFakePrompter.new(choices: ['keep'])

    result = described_class.new(
      compatibility_entry: entry,
      defaults: { 'github_username' => 'saved-user' },
      prompter: prompter
    ).run

    expect(result).to eq(github_username: 'saved-user')
    flattened = prompter.seen_options.flatten.map { |option| option.gsub(/\{\{[^:}]+:/, '').gsub('}}', '') }
    expect(flattened).to include('keep - use saved-user (default)')
    expect(flattened).to include('set - enter a value now')
    expect(flattened).not_to include('clear')
  end

  it 'treats false defaults for flags as unset' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: { git: nil }
    )
    prompter = WizardFakePrompter.new(choices: [])

    result = described_class.new(
      compatibility_entry: entry,
      defaults: { 'git' => false },
      prompter: prompter
    ).run

    expect(result).to eq({})
  end

  it 'shows bundler default labels in choices' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: {
        coc: nil,
        test: %w[rspec]
      }
    )
    prompter = WizardFakePrompter.new(choices: [])

    described_class.new(
      compatibility_entry: entry,
      defaults: {},
      bundler_defaults: { coc: false, test: 'rspec' },
      prompter: prompter
    ).run

    flattened = prompter.seen_options.flatten.map { |option| option.gsub(/\{\{[^:}]+:/, '').gsub('}}', '') }
    expect(flattened).to include('no (default)')
    expect(flattened.any? { |option| option.start_with?('rspec - ') && option.end_with?('(default)') }).to be(true)
    expect(flattened).not_to include('back')
    expect(flattened.first).to eq('no (default)')
    expect(flattened).to include('rspec - popular behavior-style testing (default)')
    expect(prompter.seen_questions.first).to include('Add CODE_OF_CONDUCT.md')
    expect(prompter.seen_questions.first).to include('Adds a code of conduct template')
  end

  it 'completes a straight-through run without back-navigation' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: { exe: nil, coc: nil }
    )
    prompter = WizardFakePrompter.new(choices: %w[yes no])

    result = described_class.new(compatibility_entry: entry, defaults: {}, prompter: prompter).run
    expect(result).to eq(exe: true, coc: false)
  end

  it 'stays at index 0 when going back on first step' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: { exe: nil }
    )
    prompter = WizardFakePrompter.new(
      choices: [CreateRubyGem::Wizard::BACK, 'yes']
    )

    result = described_class.new(compatibility_entry: entry, defaults: {}, prompter: prompter).run
    expect(result).to eq(exe: true)
  end

  it 'deletes key from result for flag answered no' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: { git: nil }
    )
    prompter = WizardFakePrompter.new(choices: %w[no])

    result = described_class.new(
      compatibility_entry: entry, defaults: { git: true }, prompter: prompter
    ).run
    expect(result).not_to have_key(:git)
  end

  it 'returns false for enum none' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: { test: %w[rspec] }
    )
    prompter = WizardFakePrompter.new(choices: %w[none])

    result = described_class.new(compatibility_entry: entry, defaults: {}, prompter: prompter).run
    expect(result).to eq(test: false)
  end

  it 'prompts for text on string set' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: { edit: nil }
    )
    prompter = WizardFakePrompter.new(choices: %w[set], texts: %w[vim])

    result = described_class.new(compatibility_entry: entry, defaults: {}, prompter: prompter).run
    expect(result).to eq(edit: 'vim')
  end

  it 'deletes key for string none' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: { edit: nil }
    )
    prompter = WizardFakePrompter.new(choices: %w[none])

    result = described_class.new(
      compatibility_entry: entry, defaults: {}, prompter: prompter
    ).run
    expect(result).not_to have_key(:edit)
  end

  it 'sanitize_defaults removes unsupported keys' do
    entry = CreateRubyGem::Compatibility::Matrix::Entry.new(
      requirement: Gem::Requirement.new('>= 0'),
      supported_options: { exe: nil }
    )
    prompter = WizardFakePrompter.new(choices: %w[yes])

    result = described_class.new(
      compatibility_entry: entry,
      defaults: { exe: true, linter: 'rubocop', changelog: true },
      prompter: prompter
    ).run
    expect(result).to eq(exe: true)
  end
end
