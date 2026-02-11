# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateRubyGem::Options::Validator do
  subject(:validator) { described_class.new(entry) }

  let(:entry) { CreateRubyGem::Compatibility::Matrix.for('4.0.4') }

  it 'accepts valid options' do
    expect(
      validator.validate!(
        gem_name: 'my_gem',
        options: { test: 'rspec', ci: false, exe: true, github_username: 'leonid' }
      )
    ).to be(true)
  end

  it 'rejects invalid gem name' do
    expect do
      validator.validate!(gem_name: '1bad', options: {})
    end.to raise_error(CreateRubyGem::ValidationError, /Invalid gem name/)
  end

  it 'rejects unknown options' do
    expect do
      validator.validate!(gem_name: 'my_gem', options: { unknown: true })
    end.to raise_error(CreateRubyGem::ValidationError, /Unknown option/)
  end

  it 'rejects unsupported option for entry' do
    old_entry = CreateRubyGem::Compatibility::Matrix.for('2.5.0')
    old_validator = described_class.new(old_entry)

    expect do
      old_validator.validate!(gem_name: 'my_gem', options: { changelog: true })
    end.to raise_error(CreateRubyGem::ValidationError, /not supported/)
  end

  it 'rejects unsupported value for entry' do
    old_entry = CreateRubyGem::Compatibility::Matrix.for('2.5.0')
    old_validator = described_class.new(old_entry)

    expect do
      old_validator.validate!(gem_name: 'my_gem', options: { ext: 'rust' })
    end.to raise_error(CreateRubyGem::ValidationError, /not supported/)
  end

  it 'rejects false for one-way flags' do
    expect do
      validator.validate!(gem_name: 'my_gem', options: { git: false })
    end.to raise_error(CreateRubyGem::ValidationError, /Invalid value/)
  end

  it 'rejects empty string gem name' do
    expect do
      validator.validate!(gem_name: '', options: {})
    end.to raise_error(CreateRubyGem::ValidationError, /Invalid gem name/)
  end

  it 'rejects nil gem name' do
    expect do
      validator.validate!(gem_name: nil, options: {})
    end.to raise_error(CreateRubyGem::ValidationError, /Invalid gem name/)
  end

  it 'rejects non-boolean for toggle' do
    expect do
      validator.validate!(gem_name: 'my_gem', options: { exe: 'yes' })
    end.to raise_error(CreateRubyGem::ValidationError, /Invalid value/)
  end

  it 'rejects non-string for string type' do
    expect do
      validator.validate!(gem_name: 'my_gem', options: { github_username: 123 })
    end.to raise_error(CreateRubyGem::ValidationError, /Invalid value/)
  end

  it 'accepts nil value for any option type' do
    expect(
      validator.validate!(gem_name: 'my_gem', options: { exe: nil, test: nil, git: nil, github_username: nil })
    ).to be(true)
  end
end
