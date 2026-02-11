# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateRubyGem::UI::Palette do
  it 'outputs 256-color ANSI codes when TERM supports it' do
    palette = described_class.new(env: { 'TERM' => 'xterm-256color', 'COLORTERM' => '' })
    result = palette.color(:summary_label, 'hello')

    expect(result).to include("\e[38;5;")
    expect(result).to include('hello')
    expect(result).to end_with(described_class::RESET)
  end

  it 'falls back to cli-ui markup on basic terminals' do
    palette = described_class.new(env: { 'TERM' => 'xterm', 'COLORTERM' => '' })
    result = palette.color(:summary_label, 'hello')

    expect(result).to eq('{{magenta:hello}}')
  end

  it 'detects truecolor via COLORTERM' do
    palette = described_class.new(env: { 'TERM' => 'xterm', 'COLORTERM' => 'truecolor' })
    result = palette.color(:arg_name, 'flag')

    expect(result).to include("\e[38;5;")
  end
end
