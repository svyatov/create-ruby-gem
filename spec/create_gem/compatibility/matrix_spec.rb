# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateGem::Compatibility::Matrix do
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
        .to raise_error(CreateGem::UnsupportedBundlerVersionError, /Supported ranges:/)
    end
  end
end
