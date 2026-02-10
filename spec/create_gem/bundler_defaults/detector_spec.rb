# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateGem::BundlerDefaults::Detector do
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
end
