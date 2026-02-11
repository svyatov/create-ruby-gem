# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe CreateRubyGem::Config::Store do
  it 'returns defaults when config file does not exist' do
    Dir.mktmpdir do |dir|
      store = described_class.new(path: File.join(dir, 'config.yml'))
      expect(store.last_used).to eq({})
      expect(store.preset_names).to eq([])
    end
  end

  it 'persists last used options' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'config.yml')
      store = described_class.new(path: path)
      store.save_last_used(test: 'rspec', ci: 'github')

      reloaded = described_class.new(path: path)
      expect(reloaded.last_used).to eq({ 'test' => 'rspec', 'ci' => 'github' })
    end
  end

  it 'supports preset CRUD' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'config.yml')
      store = described_class.new(path: path)

      store.save_preset('fast', test: 'rspec', ci: false)
      expect(store.preset('fast')).to eq({ 'test' => 'rspec', 'ci' => false })
      expect(store.preset_names).to eq(['fast'])

      store.delete_preset('fast')
      expect(store.preset('fast')).to be_nil
      expect(store.preset_names).to eq([])
    end
  end

  it 'raises on invalid yaml' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'config.yml')
      File.write(path, ':bad: :yaml: [')
      store = described_class.new(path: path)

      expect { store.last_used }.to raise_error(CreateRubyGem::ConfigError)
    end
  end

  it 'uses XDG_CONFIG_HOME when set' do
    Dir.mktmpdir do |dir|
      stub_const('ENV', ENV.to_h.merge('XDG_CONFIG_HOME' => dir))
      store = described_class.new
      expect(store.path).to eq(File.join(dir, 'create-ruby-gem', 'config.yml'))
    end
  end

  it 'falls back to ~/.config when XDG_CONFIG_HOME is unset' do
    stub_const('ENV', ENV.to_h.except('XDG_CONFIG_HOME'))
    store = described_class.new
    expect(store.path).to eq(File.join(Dir.home, '.config', 'create-ruby-gem', 'config.yml'))
  end

  it 'creates directory on first write' do
    Dir.mktmpdir do |dir|
      nested_path = File.join(dir, 'sub', 'dir', 'config.yml')
      store = described_class.new(path: nested_path)
      store.save_last_used(test: 'rspec')
      expect(File.file?(nested_path)).to be(true)
    end
  end

  it 'delete_preset is no-op for missing preset' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'config.yml')
      store = described_class.new(path: path)
      expect { store.delete_preset('nonexistent') }.not_to raise_error
    end
  end
end
