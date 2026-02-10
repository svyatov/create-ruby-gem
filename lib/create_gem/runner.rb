# frozen_string_literal: true

require 'cli/kit'
require 'shellwords'

module CreateGem
  class Runner
    def initialize(out: $stdout, system_runner: nil)
      @out = out
      @system_runner = system_runner || ->(*command) { ::CLI::Kit::System.system(*command) }
    end

    def run!(command, dry_run: false)
      if dry_run
        @out.puts(command.join(' '))
        return true
      end

      status = @system_runner.call(*command)
      return true if status.respond_to?(:success?) && status.success?

      raise Error, "Command failed: #{command.shelljoin}"
    end
  end
end
