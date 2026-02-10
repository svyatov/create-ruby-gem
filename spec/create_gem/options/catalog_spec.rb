# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateGem::Options::Catalog do
  it 'ORDER matches DEFINITIONS keys' do
    expect(described_class::ORDER).to eq(described_class::DEFINITIONS.keys)
  end

  it 'fetches a known option definition' do
    definition = described_class.fetch(:test)

    expect(definition[:type]).to eq(:enum)
    expect(definition[:values]).to include('rspec')
  end

  it 'raises KeyError for unknown option' do
    expect { described_class.fetch(:bogus) }.to raise_error(KeyError)
  end
end
