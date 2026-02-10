# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe CreateGem::UI::Prompter do
  it 'resolves Shopify CLI::UI from top-level namespace' do
    expect { described_class.new(out: StringIO.new) }.not_to raise_error
  end

  it 'maps Ctrl+B signal to back token' do
    described_class.setup!
    prompter = described_class.new(out: StringIO.new)
    allow(CLI::UI).to receive(:ask).and_raise(CreateGem::UI::BackKeyPressed)

    expect(
      prompter.choose('Pick one', options: %w[yes no], default: 'no')
    ).to eq(CreateGem::Wizard::BACK)
  end
end
