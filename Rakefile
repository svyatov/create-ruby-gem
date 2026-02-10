# frozen_string_literal: true

ENV['RUBOCOP_CACHE_ROOT'] = File.expand_path('.rubocop_cache', __dir__)

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new do |task|
  task.options = %w[--format progress --parallel --autocorrect]
end

task default: %i[spec rubocop]
