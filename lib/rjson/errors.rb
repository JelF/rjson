module RJSON
  ParseError = Class.new(StandardError)

  class PrivateKeysNotUsed < ParseError
    def self.try_raise(options, original_hash, backtrace = nil)
      return if options.empty?
      backtrace ||= caller

      keys = options.keys.map { |x| "#{Parser::PRIVATE_NAMESPACE_PREFIX}#{x}" }
      message = "Private keys #{keys} not used in #{original_hash}"

      raise self, message, backtrace
    end
  end

  class YAMLParserError < ParseError
    attr_accessor :original_error

    def initialize(original_error, *args)
      super(original_error.message, *args)
      self.original_error = original_error
    end
  end
end
