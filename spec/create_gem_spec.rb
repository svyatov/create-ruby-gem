# frozen_string_literal: true

RSpec.describe CreateGem do
  it 'has a version number' do
    expect(CreateGem::VERSION).not_to be_nil
  end
end
