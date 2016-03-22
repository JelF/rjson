require 'memoist'
require 'yaml'

module RJSON
  # Contains logic, which RJSON.load should do, except builders
  module Parser
    # Magic prefix, used to separate private namespace from hash keys
    # Probably could be changed before release
    PRIVATE_NAMESPACE_PREFIX = '__rjson_'.freeze

    extend Memoist

    module_function

    # parses data in json
    # @param raw_json [String] JSON or YAML string
    # @raise [RJSON::ParseError]
    # @return loaded object
    # @return nil if raw_json is also nil
    def parse_json(raw_json)
      parse_generic(load_json(raw_json))
    end

    # @api private
    # loads data from JSON
    # @param raw_json [String] JSON or YAML string
    # @raise [RJSON::YAMLParserError]
    # @return parsed RJSON data, mixed with YAML loaded objects
    # @return nil if raw_json is also nil
    def load_json(raw_json)
      return if raw_json.nil?
      YAML.load(raw_json)
    rescue => e
      YAMLParserError.wrap(e)
    end

    # @api private
    # contains hash of parsers, which are used depening of object class
    # @return [Hash(Class => Proc)]
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

    # @api private
    # Parses generic object
    # @param object
    # @raise [RJSON::ParseError]
    # @return loaded object
    def parse_generic(object)
      parsers[object.class].call(object)
    end

    # @api private
    # Parses RJSON string
    # @param raw_string [String]
    # @raise [RJSON::ParseError]
    #   if string is '!' prefixed and it's load causes an error
    # @return loaded object
    def parse_string(raw_string)
      case raw_string[0]
      when ':' then raw_string[1..-1].to_sym
      when '%' then raw_string[1..-1]
      when '!' then parse_json(raw_string[1..-1])
      else raw_string
      end
    end

    # @api private
    # Parses Array with RJSON objects
    # @param raw_array [Array]
    # @raise [RJSON::ParseError]
    # @return [Array] array of loaded objects
    def parse_array(raw_array)
      raw_array.map(&method(:parse_generic))
    end

    # @api private
    # @see RJSON::PrivateKeysNotUsed.try_raise
    # Parses RJSON hash
    # @param raw_hash [Hash]
    # @raise [RJSON::ParseError]
    # @raise [RJSON::PrivateKeysNotUsed]
    # @return loaded object
    def parse_hash(raw_hash)
      options, data = extract_private_options(raw_hash)
      builder = options.delete(:builder)

      if builder
        call_builder(builder, options, data)
      else
        PrivateKeysNotUsed.try_raise(options, raw_hash)
        data
      end
    end

    # @api private
    # @see RJSON::ObjectLoadError.secure_constantize
    # Uses builder to load RJSON hash with `__rjson_builder` set
    # @param builder [String] camelized builder name
    # @param options [Hash]
    #   symbolized private keys, with private prefix deleted
    # @param data [Hash]
    #   rest of hash, already loaded from RJSON
    # @raise [RJSON::ProxyError(ArgumentError)]
    #   if private keys don't match builder
    # @raise [RJSON::ObjectLoadError]
    # @raise [RJSON::ParseError]
    # @return loaded object
    def call_builder(builder, options, data)
      ObjectLoadError.secure_constantize(builder)
                     .new(options).build(data)
    rescue ArgumentError => e
      raise(e) unless e.backtrace[2][%r{rjson/parser.rb:\d+:in `call_builder'}]
      ProxyError.wrap(e)
    end

    # @api private
    # @see #parse_hash_options
    # @see #parse_hash_data
    # Separates hash to private and data sections.
    # Both returns would be returned
    # @param raw_hash [Hash]
    # @raise [RJSON::ParseError]
    # @return [Hash]
    #   private section hash, without prefixes, sybolized and with intact values
    # @return [Hash]
    #   data section hash, with keys and values both loaded
    def extract_private_options(raw_hash)
      options = raw_hash.select do |key, _|
        key.try(:starts_with?, PRIVATE_NAMESPACE_PREFIX)
      end

      data = raw_hash.select do |key, _|
        !key.try(:starts_with?, PRIVATE_NAMESPACE_PREFIX)
      end

      [parse_hash_options(options), parse_hash_data(data)]
    end

    # @api private
    # Parses private section options, removing key prefxes and symbolized them
    # @return [Hash]
    #   private section hash, without prefixes, sybolized and with intact values
    def parse_hash_options(options)
      options.map do |key, value|
        [key.sub(PRIVATE_NAMESPACE_PREFIX, '').to_sym, value]
      end.to_h
    end

    # @api private
    # Parses data section options, loading both keys and values
    # @raise [RJSON::ParseError]
    # @return [Hash]
    #   data section hash, with keys and values both loaded
    def parse_hash_data(data)
      data.map do |key, value|
        [parse_string(key), parse_generic(value)]
      end.to_h
    end
  end
end
