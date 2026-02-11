# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateRubyGem::Compatibility::Matrix do
  describe '.for' do
    it 'returns a match for bundler 4.x' do
      entry = described_class.for('4.0.4')
      expect(entry.supports_option?(:linter)).to be(true)
      expect(entry.allowed_values(:ext)).to include('rust')
    end

    it 'returns a match for bundler 2.x' do
      entry = described_class.for('2.5.0')
      expect(entry.allowed_values(:ext)).to eq(['c'])
      expect(entry.supports_option?(:changelog)).to be(false)
    end

    it 'raises for unsupported versions' do
      expect { described_class.for('1.17.2') }
        .to raise_error(CreateRubyGem::UnsupportedBundlerVersionError, /Supported ranges:/)
    end

    it 'returns a match for bundler 3.x' do
      entry = described_class.for('3.1.0')
      expect(entry.supports_option?(:changelog)).to be(true)
      expect(entry.supports_option?(:linter)).to be(true)
      expect(entry.allowed_values(:ext)).to eq(%w[c])
    end

    it 'raises for version below minimum' do
      expect { described_class.for('2.3.9') }
        .to raise_error(CreateRubyGem::UnsupportedBundlerVersionError)
    end
  end

  describe '.supported_ranges' do
    it 'returns an array of range strings' do
      ranges = described_class.supported_ranges
      expect(ranges).to be_an(Array)
      expect(ranges.length).to eq(described_class::TABLE.length)
    end
  end

  describe CreateRubyGem::Compatibility::Matrix::Entry do
    it 'returns nil for toggle allowed_values' do
      entry = described_class.new(
        requirement: Gem::Requirement.new('>= 0'),
        supported_options: { exe: nil }
      )
      expect(entry.allowed_values(:exe)).to be_nil
    end
  end
end
