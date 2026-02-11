# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateRubyGem::Detection::BundlerDefaults do
  it 'returns fallbacks when no settings are available' do
    defaults = described_class.new(settings: nil).detect

    expect(defaults[:exe]).to eq(false)
    expect(defaults[:git]).to eq(true)
    expect(defaults[:bundle_install]).to eq(false)
    expect(defaults[:test]).to be_nil
  end

  it 'maps bundler settings to option defaults' do
    settings = {
      'gem.coc' => false,
      'gem.changelog' => true,
      'gem.test' => 'rspec',
      'gem.ci' => 'github',
      'gem.linter' => 'rubocop'
    }

    defaults = described_class.new(settings: settings).detect

    expect(defaults[:coc]).to eq(false)
    expect(defaults[:changelog]).to eq(true)
    expect(defaults[:test]).to eq('rspec')
    expect(defaults[:ci]).to eq('github')
    expect(defaults[:linter]).to eq('rubocop')
  end

  it 'only overrides keys present in settings' do
    settings = { 'gem.test' => 'rspec' }
    defaults = described_class.new(settings: settings).detect

    expect(defaults[:test]).to eq('rspec')
    expect(defaults[:exe]).to eq(false)
    expect(defaults[:ci]).to be_nil
  end

  it 'returns fallbacks when settings raise StandardError' do
    settings = Object.new
    def settings.[](_key) = raise(StandardError, 'boom')

    defaults = described_class.new(settings: settings).detect
    expect(defaults).to eq(described_class::FALLBACKS)
  end

  it 'returns fallbacks when Bundler.settings raises NoMethodError' do
    stub_const('Bundler', Module.new)
    defaults = described_class.new.detect

    expect(defaults).to eq(described_class::FALLBACKS)
  end

  it 'normalizes string booleans to actual booleans' do
    settings = { 'gem.coc' => 'true', 'gem.mit' => 'false' }
    defaults = described_class.new(settings: settings).detect

    expect(defaults[:coc]).to be(true)
    expect(defaults[:mit]).to be(false)
  end
end
