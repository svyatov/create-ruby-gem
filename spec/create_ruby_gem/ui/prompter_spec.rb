# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe CreateRubyGem::UI::Prompter do
  it 'resolves Shopify CLI::UI from top-level namespace' do
    expect { described_class.new(out: StringIO.new) }.not_to raise_error
  end

  it 'maps Ctrl+B signal to back token' do
    described_class.setup!
    prompter = described_class.new(out: StringIO.new)
    allow(CLI::UI).to receive(:ask).and_raise(CreateRubyGem::UI::BackKeyPressed)

    expect(
      prompter.choose('Pick one', options: %w[yes no], default: 'no')
    ).to eq(CreateRubyGem::Wizard::BACK)
  end

  it '#say outputs formatted text' do
    out = StringIO.new
    prompter = described_class.new(out: out)
    allow(CLI::UI).to receive(:fmt).with('hello').and_return('hello')

    prompter.say('hello')
    expect(out.string).to eq("hello\n")
  end

  it '#text delegates to CLI::UI.ask' do
    prompter = described_class.new(out: StringIO.new)
    allow(CLI::UI).to receive(:ask).with('Name:', default: nil, allow_empty: true).and_return('alice')

    expect(prompter.text('Name:')).to eq('alice')
  end

  it '#confirm delegates to CLI::UI.confirm' do
    prompter = described_class.new(out: StringIO.new)
    allow(CLI::UI).to receive(:confirm).with('Sure?', default: true).and_return(true)

    expect(prompter.confirm('Sure?')).to be(true)
  end
end
