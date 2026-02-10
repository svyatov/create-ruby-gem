# frozen_string_literal: true

module CreateGem
  module UI
    class BackKeyPressed < StandardError; end

    module InteractiveKeymap
      CTRL_B = "\u0002"

      module PromptReadCharPatch
        def read_char
          char = super

          raise BackKeyPressed if char == InteractiveKeymap::CTRL_B

          char
        end
      end

      module_function

      def apply!
        singleton = ::CLI::UI::Prompt.singleton_class
        return if singleton.ancestors.include?(PromptReadCharPatch)

        singleton.prepend(PromptReadCharPatch)
      end
    end
  end
end
