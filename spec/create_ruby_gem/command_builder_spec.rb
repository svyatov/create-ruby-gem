# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateRubyGem::CommandBuilder do
  subject(:builder) do
    described_class.new(compatibility_entry: CreateRubyGem::Compatibility::Matrix.for('4.0.4'))
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

  it 'emits string option with value' do
    command = builder.build(gem_name: 'my_gem', options: { github_username: 'leonid' })
    expect(command).to include('--github-username=leonid')
  end

  it 'emits flag when true' do
    command = builder.build(gem_name: 'my_gem', options: { git: true })
    expect(command).to include('--git')
  end

  it 'emits --no-* for toggle false' do
    command = builder.build(gem_name: 'my_gem', options: { exe: false })
    expect(command).to include('--no-exe')
  end

  it 'skips empty string values' do
    command = builder.build(gem_name: 'my_gem', options: { github_username: '' })
    expect(command).to eq(%w[bundle gem my_gem])
  end

  it 'builds minimal command with no options' do
    command = builder.build(gem_name: 'my_gem')
    expect(command).to eq(%w[bundle gem my_gem])
  end
end
