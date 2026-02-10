# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateGem::Command::Builder do
  subject(:builder) { described_class.new(bundler_version: '4.0.4') }

  it 'builds a bundle gem command with supported flags' do
    command = builder.build(
      gem_name: 'my_gem',
      options: {
        exe: true,
        test: 'rspec',
        ci: 'github',
        linter: 'rubocop',
        ext: 'rust',
        bundle_install: false
      }
    )

    expect(command).to eq(
      [
        'bundle', 'gem', 'my_gem',
        '--exe',
        '--ext=rust',
        '--test=rspec',
        '--ci=github',
        '--linter=rubocop',
        '--no-bundle'
      ]
    )
  end

  it 'supports no-* enum values' do
    command = builder.build(gem_name: 'my_gem', options: { test: false, ci: false, linter: false, ext: false })
    expect(command).to include('--no-test', '--no-ci', '--no-linter', '--no-ext')
  end

  it 'raises for invalid values' do
    expect do
      builder.build(gem_name: 'my_gem', options: { ci: 'unknown' })
    end.to raise_error(CreateGem::ValidationError)
  end
end
