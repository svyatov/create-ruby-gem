# frozen_string_literal: true

module CreateGem
  module Command
    class Builder
      def initialize(bundler_version:)
        @compatibility_entry = Compatibility::Matrix.for(bundler_version)
      end

      def build(gem_name:, options: {})
        normalized_options = symbolize_keys(options)
        Options::Validator.new(@compatibility_entry).validate!(gem_name: gem_name, options: normalized_options)

        command = ['bundle', 'gem', gem_name]
        Options::Catalog::ORDER.each do |key|
          next unless normalized_options.key?(key)

          append_option!(command, key, normalized_options[key])
        end
        command
      end

      private

      def symbolize_keys(hash)
        hash.transform_keys(&:to_sym)
      end

      def append_option!(command, key, value)
        definition = Options::Catalog.fetch(key)
        case definition[:type]
        when :toggle
          command << definition[:on] if value == true
          command << definition[:off] if value == false
        when :flag
          command << definition[:on] if value == true
        when :enum
          command << "#{definition[:flag]}=#{value}" if value.is_a?(String)
          command << definition[:none] if value == false
        when :string
          command << "#{definition[:flag]}=#{value}" if value.is_a?(String) && !value.empty?
        end
      end
    end
  end
end
