# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'executable integration' do
  it 'runs directly without bundle exec' do
    exe = File.expand_path('../../../exe/create-ruby-gem', __dir__)
    output, status = Open3.capture2e(exe, '--version')

    expect(status.success?).to be(true), output
    expect(output).to eq("#{CreateRubyGem::VERSION}\n")
  end
end
