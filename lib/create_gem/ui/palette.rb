# frozen_string_literal: true

module CreateGem
  module UI
    class Palette
      RESET = "\e[0m"

      ROLE_COLORS_256 = {
        control_back: 45,
        control_exit: 203,
        summary_label: 213,
        runtime_name: 111,
        runtime_value: 190,
        command_base: 39,
        command_gem: 82,
        arg_name: 117,
        arg_eq: 250,
        arg_value: 214
      }.freeze

      ROLE_COLORS_BASIC = {
        control_back: 'cyan',
        control_exit: 'red',
        summary_label: 'magenta',
        runtime_name: 'blue',
        runtime_value: 'green',
        command_base: 'blue',
        command_gem: 'green',
        arg_name: 'blue',
        arg_eq: 'white',
        arg_value: 'yellow'
      }.freeze

      def initialize(env: ENV)
        @env = env
      end

      def color(role, text)
        if supports_256_colors?
          "\e[38;5;#{ROLE_COLORS_256.fetch(role)}m#{text}#{RESET}"
        else
          "{{#{ROLE_COLORS_BASIC.fetch(role)}:#{text}}}"
        end
      end

      private

      def supports_256_colors?
        term = @env.fetch('TERM', '')
        colorterm = @env.fetch('COLORTERM', '')
        term.include?('256color') || colorterm.match?(/truecolor|24bit|256/i)
      end
    end
  end
end
