# frozen_string_literal: true

module CreateGem
  module Options
    class Validator
      GEM_NAME_PATTERN = /\A[a-zA-Z][a-zA-Z0-9_-]*\z/

      def initialize(compatibility_entry)
        @compatibility_entry = compatibility_entry
      end

      def validate!(gem_name:, options:) # rubocop:disable Naming/PredicateMethod
        validate_gem_name!(gem_name)

        options.each do |key, value|
          validate_option_key!(key)
          validate_supported_option!(key)
          validate_value!(key, value)
          validate_supported_value!(key, value)
        end

        true
      end

      private

      def validate_gem_name!(gem_name)
        return if gem_name.is_a?(String) && gem_name.match?(GEM_NAME_PATTERN)

        raise ValidationError, "Invalid gem name: #{gem_name.inspect}"
      end

      def validate_option_key!(key)
        return if Catalog::DEFINITIONS.key?(key.to_sym)

        raise ValidationError, "Unknown option: #{key}"
      end

      def validate_supported_option!(key)
        return if @compatibility_entry.supports_option?(key)

        raise ValidationError, "Option #{key} is not supported by this bundler version"
      end

      def validate_value!(key, value)
        definition = Catalog.fetch(key)
        case definition[:type]
        when :toggle
          return if value.nil? || value == true || value == false
        when :flag
          return if value.nil? || value == true
        when :enum
          return if value.nil? || value == false || definition[:values].include?(value)
        when :string
          return if value.nil? || value.is_a?(String)
        end

        raise ValidationError, "Invalid value for #{key}: #{value.inspect}"
      end

      def validate_supported_value!(key, value)
        return if value.nil? || value == true || value == false

        supported_values = @compatibility_entry.allowed_values(key)
        return if supported_values.nil? || supported_values.include?(value)

        raise ValidationError, "Value #{value.inspect} for #{key} is not supported by this bundler version"
      end
    end
  end
end
