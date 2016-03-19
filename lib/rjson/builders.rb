require 'memoist'

module RJSON
  class Builder
    def initialize(options = {})
      raise "Unexpected options: #{options}" if options.present?
    end
  end

  class ObjectBuilder < Builder
    class BadKey < ::RJSON::ParseError
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
    attr_accessor :class_name

    def initialize(class_name:)
      self.class_name = class_name
    end

    def build(data)
      data.each_with_object(klass.allocate) do |(key, value), new_object|
        BadKey.try_raise(key)
        new_object.instance_variable_set(key, value)
      end
    end

    def klass
      ObjectLoadError.secure_constantize(class_name)
    end
    memoize :klass
  end

  class ConstantLoader < Builder
    def build(name:)
      ObjectLoadError.secure_constantize(name)
    end
  end

  class FunctionalBuilder < Builder
    def build(method:, args:, namespace: Kernel)
      namespace.public_send(method, *args)
    end
  end
end
