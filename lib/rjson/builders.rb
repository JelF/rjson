require 'memoist'

module RJSON
  # Generic builder superclass.
  # Builders are classes with duck type `.new(options = {})`
  # and `.build(data = {})`, which could be referenced from rjson
  class Builder
    # @param options [Hash(Symbol => Object)]
    #   options, normally prefixed by `__rjson_`, but with this prefix
    #   removed and symbolized
    # @raise [ParseError] if any options given
    # Default implementation
    def initialize(options = {})
      raise ParseError, "Unexpected options: #{options}" if options.present?
    end
  end

  # Builds an object, which could be described by it's ivars.
  # It is almost any object, except objects inherited from primitive types
  class ObjectBuilder < Builder
    # Raised if data is malformed
    class BadKey < ::RJSON::ParseError
      # Try raise is a generic error API in this project, which delegates
      # conditional raises to errors.
      # @param key [String]
      # @raise [RJSON::ObjectBuilder::BadKey] if key is not in `/@[^@]+/` format
      def self.try_raise(key)
        if !key.starts_with?('@')
          raise self,
                "Key #{key} should have '@' prefix to set object ivar",
                caller
        elsif key.starts_with?('@@')
          raise self,
                "Key #{key} should not start with double '@@'",
                caller
        end
      end
    end

    extend Memoist
    # name of class, received from options to separate it from class data
    attr_accessor :class_name

    # @param class_name [String]
    #  name of class to be built (camelized)
    def initialize(class_name:)
      self.class_name = class_name
    end

    # @param data [Hash]
    #   list of ivars, prefixed by '@'
    # @raise [RJSON::ObjectBuilder::BadKey]
    # @return instance of klass
    def build(data)
      data.each_with_object(klass.allocate) do |(key, value), new_object|
        BadKey.try_raise(key)
        new_object.instance_variable_set(key, value)
      end
    end

    # @return [Class] constantized class_name
    # @raise [RJSON::ObjectLoadError(NameError)] if class not found
    def klass
      ObjectLoadError.secure_constantize(class_name)
    end
    memoize :klass
  end

  # Simply constantizes name like `Float::INFINITY`
  class ConstantLoader < Builder
    # @param name [String]
    #   camelized constant name
    # @raise [RJSON::ObjectLoadError(NameError)] if constant not found
    # @return value of generic constant
    def build(name:)
      ObjectLoadError.secure_constantize(name)
    end
  end

  # Simply calls method with given args like `Rational(1,2)`
  # or maybe `:foo.to_proc`, why not?
  class FunctionalBuilder < Builder
    # @param method [Symbol]
    #    public method name
    # @param args [Array]
    #    generic list of args
    # @param namespace [Object]
    #    object, on which method should be called
    # @raise [RJSON::ProxyError(NameError)] if method missing
    # @return result of method public call
    def build(method:, args:, namespace: Kernel)
      namespace.public_send(method, *args)
    rescue NameError => e
      raise(e) unless e.name == method
      ProxyError.wrap(e)
    end
  end
end
