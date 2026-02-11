# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'tmpdir'

RSpec.describe 'create-ruby-gem integration' do
  let(:preset_name) { 'ci_rspec' }
  let(:preset_options) do
    {
      exe: false,
      coc: false,
      changelog: false,
      ext: false,
      git: true,
      github_username: 'leonid',
      mit: false,
      test: 'rspec',
      ci: 'github',
      linter: 'rubocop',
      bundle_install: false
    }
  end

  it 'creates a gem from preset options end-to-end' do
    Dir.mktmpdir do |tmpdir|
      store = CreateRubyGem::Config::Store.new(path: File.join(tmpdir, 'config', 'config.yml'))
      store.save_preset(preset_name, preset_options)

      gem_name = 'demo_generated_gem'
      out = StringIO.new
      err = StringIO.new

      status = Dir.chdir(tmpdir) do
        CreateRubyGem::CLI.start([gem_name, '--preset', preset_name], out: out, err: err, store: store)
      end

      expect(status).to eq(0), "stderr: #{err.string}\nstdout: #{out.string}"
      expect(File).to exist(File.join(tmpdir, gem_name, "#{gem_name}.gemspec"))
      expect(File).to exist(File.join(tmpdir, gem_name, 'README.md'))
      expect(File).to exist(File.join(tmpdir, gem_name, 'spec', 'spec_helper.rb'))
      expect(File).to exist(File.join(tmpdir, gem_name, '.github', 'workflows', 'main.yml'))
      expect(store.last_used).to include('test' => 'rspec', 'ci' => 'github')
    end
  end

  it 'does not create a gem directory in dry-run mode' do
    Dir.mktmpdir do |tmpdir|
      store = CreateRubyGem::Config::Store.new(path: File.join(tmpdir, 'config', 'config.yml'))
      store.save_preset(preset_name, preset_options)

      gem_name = 'demo_dry_run_gem'
      out = StringIO.new
      err = StringIO.new

      status = Dir.chdir(tmpdir) do
        CreateRubyGem::CLI.start([gem_name, '--preset', preset_name, '--dry-run'], out: out, err: err, store: store)
      end

      expect(status).to eq(0), "stderr: #{err.string}\nstdout: #{out.string}"
      expect(out.string).to include("bundle gem #{gem_name}")
      expect(File).not_to exist(File.join(tmpdir, gem_name))
    end
  end
end
