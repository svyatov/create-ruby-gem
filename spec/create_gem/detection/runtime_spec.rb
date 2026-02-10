# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateGem::Detection::Runtime do
  it 'returns ruby, rubygems and bundler versions' do
    bundler_detector = instance_double(CreateGem::Detection::BundlerVersion, detect!: Gem::Version.new('4.0.4'))
    versions = described_class.new(bundler_detector: bundler_detector).detect!

    expect(versions.ruby).to be_a(Gem::Version)
    expect(versions.rubygems).to be_a(Gem::Version)
    expect(versions.bundler).to eq(Gem::Version.new('4.0.4'))
  end

  it 'propagates UnsupportedBundlerVersionError from bundler detector' do
    bundler_detector = instance_double(CreateGem::Detection::BundlerVersion)
    allow(bundler_detector).to receive(:detect!).and_raise(
      CreateGem::UnsupportedBundlerVersionError, 'not found'
    )

    expect { described_class.new(bundler_detector: bundler_detector).detect! }
      .to raise_error(CreateGem::UnsupportedBundlerVersionError, 'not found')
  end
end
