# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateGem::Detection::BundlerVersion do
  it 'parses version from standard output' do
    detector = described_class.new(bundle_command: 'echo')
    allow(IO).to receive(:popen).and_return("Bundler version 2.5.6\n")

    expect(detector.detect!).to eq(Gem::Version.new('2.5.6'))
  end

  it 'extracts version from multi-line output with warnings' do
    detector = described_class.new
    allow(IO).to receive(:popen).and_return("WARNING: something\nBundler version 3.1.0\n")

    expect(detector.detect!).to eq(Gem::Version.new('3.1.0'))
  end

  it 'raises on garbage output' do
    detector = described_class.new
    allow(IO).to receive(:popen).and_return('no version here')

    expect { detector.detect! }.to raise_error(
      CreateGem::UnsupportedBundlerVersionError, /Cannot parse bundler version/
    )
  end

  it 'raises when bundle executable is not found' do
    detector = described_class.new(bundle_command: 'nonexistent_bundle_binary')
    allow(IO).to receive(:popen).and_raise(Errno::ENOENT)

    expect { detector.detect! }.to raise_error(
      CreateGem::UnsupportedBundlerVersionError, /Bundler executable not found/
    )
  end
end
