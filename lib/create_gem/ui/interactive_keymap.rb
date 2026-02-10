# frozen_string_literal: true

module CreateGem
  module UI
    # Raised when the user presses Ctrl+B during a prompt.
    #
    # @api private
    class BackKeyPressed < StandardError; end

    # Monkey-patches +CLI::UI::Prompt+ to intercept Ctrl+B for back-navigation.
    #
    # @api private
    module InteractiveKeymap
      # ASCII code for Ctrl+B.
      CTRL_B = "\u0002"

      # Patch module prepended onto +CLI::UI::Prompt.singleton_class+.
      module PromptReadCharPatch
        # @raise [BackKeyPressed] when the user presses Ctrl+B
        # @return [String] the character read
        def read_char
          char = super

          raise BackKeyPressed if char == InteractiveKeymap::CTRL_B

          char
        end
      end

      module_function

      # Prepends the Ctrl+B patch onto +CLI::UI::Prompt+ (idempotent).
      #
      # @return [void]
      def apply!
        singleton = ::CLI::UI::Prompt.singleton_class
        return if singleton.ancestors.include?(PromptReadCharPatch)

        singleton.prepend(PromptReadCharPatch)
      end
    end
  end
end
