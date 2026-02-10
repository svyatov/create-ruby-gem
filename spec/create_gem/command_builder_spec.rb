# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateGem::CommandBuilder do
  subject(:builder) do
    described_class.new(compatibility_entry: CreateGem::Compatibility::Matrix.for('4.0.4'))
  end

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
end
