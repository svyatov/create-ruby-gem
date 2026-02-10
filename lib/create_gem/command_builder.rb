# frozen_string_literal: true

module CreateGem
  # Converts a gem name and option hash into a +bundle gem+ command array.
  #
  # @example
  #   entry = Compatibility::Matrix.for('3.1.0')
  #   builder = CommandBuilder.new(compatibility_entry: entry)
  #   builder.build(gem_name: 'my_gem', options: { exe: true, test: 'rspec' })
  #   #=> ['bundle', 'gem', 'my_gem', '--exe', '--test=rspec']
  class CommandBuilder
    # @param compatibility_entry [Compatibility::Matrix::Entry]
    def initialize(compatibility_entry:)
      @compatibility_entry = compatibility_entry
    end

    # Builds the +bundle gem+ command array.
    #
    # @param gem_name [String]
    # @param options [Hash{Symbol => Object}]
    # @return [Array<String>]
    def build(gem_name:, options: {})
      command = ['bundle', 'gem', gem_name]
      Options::Catalog::ORDER.each do |key|
        next unless options.key?(key)

        append_option!(command, key, options[key])
      end
      command
    end

    private

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
