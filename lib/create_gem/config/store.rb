# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'yaml'

module CreateGem
  module Config
    class Store
      SCHEMA_VERSION = 1

      def initialize(path: nil)
        @path = path || default_path
      end

      attr_reader :path

      def last_used
        data.fetch('last_used')
      end

      def save_last_used(options)
        payload = data
        payload['last_used'] = stringify_keys(options)
        write(payload)
      end

      def preset(name)
        data.fetch('presets').fetch(name.to_s, nil)
      end

      def preset_names
        data.fetch('presets').keys.sort
      end

      def save_preset(name, options)
        payload = data
        payload.fetch('presets')[name.to_s] = stringify_keys(options)
        write(payload)
      end

      def delete_preset(name)
        payload = data
        payload.fetch('presets').delete(name.to_s)
        write(payload)
      end

      private

      def data
        raw = load
        {
          'version' => raw.fetch('version', SCHEMA_VERSION),
          'last_used' => raw.fetch('last_used', {}),
          'presets' => raw.fetch('presets', {})
        }
      end

      def load
        return {} unless File.file?(path)

        YAML.safe_load_file(path, aliases: false) || {}
      rescue Psych::SyntaxError => e
        raise ConfigError, "Invalid config file at #{path}: #{e.message}"
      end

      def write(payload)
        FileUtils.mkdir_p(File.dirname(path))
        Tempfile.create(['create-gem', '.yml'], File.dirname(path)) do |tmp|
          tmp.write(YAML.dump(payload))
          tmp.flush
          File.rename(tmp.path, path)
        end
      end

      def default_path
        config_home = ENV.fetch('XDG_CONFIG_HOME', File.join(Dir.home, '.config'))
        File.join(config_home, 'create-gem', 'config.yml')
      end

      def stringify_keys(hash)
        hash.transform_keys(&:to_s)
      end
    end
  end
end
