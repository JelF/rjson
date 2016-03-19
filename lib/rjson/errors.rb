module RJSON
  ParseError = Class.new(StandardError)

  class PrivateKeysNotUsed < ParseError
    def self.try_raise(options, original_hash)
      return if options.empty?

      keys = options.keys.map { |x| "#{Parser::PRIVATE_NAMESPACE_PREFIX}#{x}" }
      message = "Private keys #{keys} not used in #{original_hash}"

      raise self, message, caller
    end
  end

  class ProxyError < ParseError
    attr_accessor :original_error

    def initialize(original_error)
      super(original_error.message)
      self.original_error = original_error
    end
  end

  YAMLParserError = Class.new(ProxyError)

  class ObjectLoadError < ProxyError
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
