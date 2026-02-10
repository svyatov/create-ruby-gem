# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe CreateGem::Config::Store do
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

      expect { store.last_used }.to raise_error(CreateGem::ConfigError)
    end
  end
end
