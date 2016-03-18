require 'memoist'
require 'yaml'

module RJSON
  module Parser
    PRIVATE_NAMESPACE_PREFIX = '__rjson_'.freeze

    extend Memoist

    module_function

    def parse_json(raw_json)
      parse_generic(load_json(raw_json))
    end

    def load_json(raw_json)
      YAML.load(raw_json)
    rescue => e
      raise YAMLParserError.new(e)
    end

    def parsers
      result = {
        String => method(:parse_string),
        Array => method(:parse_array),
        Hash => method(:parse_hash)
      }
      result.default = -> (x) { x }
      result
    end
    memoize :parsers

    def parse_generic(object)
      parsers[object.class].call(object)
    end

    def parse_string(raw_string)
      case raw_string[0]
      when ':' then raw_string[1..-1].to_sym
      when '%' then raw_string[1..-1]
      else raw_string
      end
    end

    def parse_array(raw_array)
      raw_array.map(&method(:parse_generic))
    end

    def parse_hash(raw_hash)
      options, data = extract_private_options(raw_hash)
      builder = options.delete(:builder)

      if builder
        builder.camelize.constantize.new(options).build(data)
      else
        PrivateKeysNotUsed.try_raise(options, raw_hash)
        data
      end
    end

    def extract_private_options(raw_hash)
      options = raw_hash.select do |key, _|
        key.try(:starts_with?, PRIVATE_NAMESPACE_PREFIX)
      end

      data = raw_hash.select do |key, _|
        !key.try(:starts_with?, PRIVATE_NAMESPACE_PREFIX)
      end

      [parse_hash_options(options), parse_hash_data(data)]
    end

    def parse_hash_options(options)
      options.map do |key, value|
        [key.sub(PRIVATE_NAMESPACE_PREFIX, '').to_sym, value]
      end.to_h
    end

    def parse_hash_data(data)
      data.map do |key, value|
        [parse_string(key), parse_generic(value)]
      end.to_h
    end
  end
end
