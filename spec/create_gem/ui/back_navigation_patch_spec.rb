# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateGem::UI::BackNavigationPatch do
  it 'raises BackKeyPressed on Ctrl+B' do
    base_class = Class.new { def read_char = "\u0002" }
    patched_class = Class.new(base_class) { prepend CreateGem::UI::BackNavigationPatch::PromptReadCharPatch }

    expect { patched_class.new.read_char }.to raise_error(CreateGem::UI::BackKeyPressed)
  end

  it 'passes through normal characters' do
    base_class = Class.new { def read_char = 'a' }
    patched_class = Class.new(base_class) { prepend CreateGem::UI::BackNavigationPatch::PromptReadCharPatch }

    expect(patched_class.new.read_char).to eq('a')
  end
end
