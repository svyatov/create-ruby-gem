# frozen_string_literal: true

module CreateGem
  module Command
    # Converts a gem name and option hash into a +bundle gem+ command array.
    #
    # Validates all options via {Options::Validator} before building.
    #
    # @example
    #   builder = Builder.new(bundler_version: '3.1.0')
    #   builder.build(gem_name: 'my_gem', options: { exe: true, test: 'rspec' })
    #   #=> ['bundle', 'gem', 'my_gem', '--exe', '--test=rspec']
    class Builder
      # @param bundler_version [Gem::Version, String]
      def initialize(bundler_version:)
        @compatibility_entry = Compatibility::Matrix.for(bundler_version)
      end

      # Builds the +bundle gem+ command array.
      #
      # @param gem_name [String]
      # @param options [Hash{Symbol => Object}]
      # @return [Array<String>]
      # @raise [ValidationError] if any option is invalid
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

      # @param hash [Hash]
      # @return [Hash{Symbol => Object}]
      def symbolize_keys(hash)
        hash.transform_keys(&:to_sym)
      end

      # @param command [Array<String>]
      # @param key [Symbol]
      # @param value [Object]
      # @return [void]
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
