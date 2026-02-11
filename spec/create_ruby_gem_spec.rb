# frozen_string_literal: true

RSpec.describe CreateRubyGem do
  it 'has a version number' do
    expect(CreateRubyGem::VERSION).not_to be_nil
  end
end
