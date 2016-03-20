module RJSON
  # Superclass of errors, which could be raised when parsing RJSON file.
  ParseError = Class.new(StandardError)

  # Raised if object has private keys (keys, prefixed with `__rjson_`),
  # but no builder uses them
  class PrivateKeysNotUsed < ParseError
    # Try raise is a generic error API in this project, which delegates
    # conditional raises to errors.
    # @param options [Hash]
    # @param original_hash [Hash]
    # @raise [RJSON::PrivateKeysNotUsed] if options not empty
    def self.try_raise(options, original_hash)
      return if options.empty?

      keys = options.keys.map { |x| "#{Parser::PRIVATE_NAMESPACE_PREFIX}#{x}" }
      message = "Private keys #{keys} not used in #{original_hash}"

      raise self, message, caller
    end
  end

  # Allows to easily wrap generic errors into ParseError
  class ProxyError < ParseError
    # References riginal error, which ActiveSupport will also show in backtrace!
    # Also could be directly called to get Exception instance
    attr_accessor :original_error

    # Raises ProxyError with original_error attributes
    # @param original_error [Exception]
    # @raise [ProxyError]
    def self.wrap(original_error)
      raise(
        new(original_error),
        original_error.message,
        original_error.backtrace,
      )
    end

    # @param original_error [Exception]
    def initialize(original_error)
      super(original_error.message)
      self.original_error = original_error
    end
  end

  # Wraps errors, caused by YAML parser
  YAMLParserError = Class.new(ProxyError)

  # Wraps errors, caused by missing objects, referenced from RJSON
  class ObjectLoadError < ProxyError
    # Same as ActiveSupport constantize, but raises ObjectLoadErrors
    # @param name [String] camelized constant name
    # @raise ObjectLoadError
    # @return constant value
    def self.secure_constantize(name)
      name.constantize
    rescue NameError => e
      if e.name.in?(name.split('::'))
        raise new(e), e.message, caller(2)
      else
        raise(e)
      end
    end
  end
end
