# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe CreateGem::Runner do
  it 'prints dry-run command' do
    out = StringIO.new
    described_class.new(out: out).run!(%w[bundle gem my_gem --test=rspec], dry_run: true)
    expect(out.string).to include('bundle gem my_gem --test=rspec')
  end

  it 'raises when command execution fails' do
    runner = described_class.new(out: StringIO.new, system_runner: ->(*) { false })

    expect do
      runner.run!(%w[bundle gem my_gem])
    end.to raise_error(CreateGem::Error, /Command failed/)
  end

  it 'returns true on successful execution' do
    status = instance_double(Process::Status, success?: true)
    runner = described_class.new(out: StringIO.new, system_runner: ->(*) { status })

    expect(runner.run!(%w[bundle gem my_gem])).to be(true)
  end
end
