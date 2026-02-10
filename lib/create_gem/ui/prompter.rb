# frozen_string_literal: true

require 'cli/ui'
require_relative 'interactive_keymap'

module CreateGem
  module UI
    class Prompter
      def initialize(out: $stdout)
        @out = out
        ::CLI::UI::StdoutRouter.enable
        InteractiveKeymap.apply!
      end

      def frame(title, &)
        ::CLI::UI::Frame.open(title, &)
      end

      def choose(question, options:, default: nil)
        ::CLI::UI.ask(question, options: options, default: default, filter_ui: false)
      rescue BackKeyPressed
        Wizard::Session::BACK
      end

      def text(question, default: nil, allow_empty: true)
        ::CLI::UI.ask(question, default: default, allow_empty: allow_empty)
      end

      def confirm(question, default: true)
        ::CLI::UI.confirm(question, default: default)
      end

      def say(message)
        @out.puts(::CLI::UI.fmt(message))
      end
    end
  end
end
