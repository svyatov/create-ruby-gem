# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateGem::RuntimeVersions::Detector do
  it 'returns ruby, rubygems and bundler versions' do
    bundler_detector = instance_double(CreateGem::BundlerVersion::Detector, detect!: Gem::Version.new('4.0.4'))
    versions = described_class.new(bundler_detector: bundler_detector).detect!

    expect(versions.ruby).to be_a(Gem::Version)
    expect(versions.rubygems).to be_a(Gem::Version)
    expect(versions.bundler).to eq(Gem::Version.new('4.0.4'))
  end
end
