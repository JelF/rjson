module RJSON
  class Dumper
    def self.priority
      500
    end

    def self.to_json(object)
      dump(object).to_json
    end

    def self.dump(object)
      return object.to_rjson if object.respond_to?(:to_rjson)
      choose_object_dumper(object).new(object).dump
    end

    def self.choose_object_dumper(object)
      DUMPERS.find { |x| x.can_dump?(object) }
    end

    def self.can_dump?(_object)
      false
    end

    def initialize(object)
      self.object = object
    end

    def dump_hash(object)
      # Symbolizing keys to unlock **intepolation
      ObjectDumper.dump(object).symbolize_keys
    end

    private

    attr_accessor :object
  end

  class PrimitiveTypesDumper < Dumper
    def self.can_dump?(object)
      object.class.in?([Integer, Fixnum, Bignum]) ||
        object.in?([true, false, nil])
    end

    alias dump object
    public(:dump)
  end

  class FloatDumper < Dumper
    def self.can_dump?(object)
      object.class == Float
    end

    def dump
      if object == Float::INFINITY
        {
          '__rjson_builder' => 'RJSON::ConstantLoader',
          **dump_hash(name: 'Float::INFINITY')
        }
      else
        object
      end
    end
  end

  class StringDumper < Dumper
    def self.can_dump?(object)
      object.class == String
    end

    def dump
      "%#{object}"
    end
  end

  class SymbolDumper < Dumper
    def self.can_dump?(object)
      object.class == Symbol
    end

    def dump
      ":#{object}"
    end
  end

  class ArrayDumper < Dumper
    def self.can_dump?(object)
      object.class == Array
    end

    def dump
      object.map { |x| self.class.dump(x) }
    end
  end

  class HashDumper < Dumper
    def self.can_dump?(object)
      object.class == Hash
    end

    def dump
      object.map do |key, value|
        dumped_key = self.class.dump(key)
        dumped_key = "!#{dumped_key.to_json}" unless dumped_key.is_a?(String)
        [dumped_key, self.class.dump(value)]
      end.to_h
    end
  end

  class StringRepresentableDumper < Dumper
    def self.can_dump?(object)
      object.class.in?([BigDecimal, Complex])
    end

    def namespace
      namespace_name = object.class.name.deconstantize
      return if namespace_name.blank?

      {
        '__rjson_builder' => 'RJSON::ConstantLoader',
        **dump_hash(name: namespace_name)
      }
    end

    def dump
      {
        '__rjson_builder' => 'RJSON::FunctionalBuilder',
        ':namespace' => namespace,
        **dump_hash(method: object.class.name.demodulize, args: [object.to_s])
      }.compact
    end
  end

  class RationalDumper < Dumper
    def self.can_dump?(object)
      object.class == Rational
    end

    def dump
      {
        '__rjson_builder' => 'RJSON::FunctionalBuilder',
        **dump_hash(method: 'Rational',
                    args: [object.numerator, object.denominator])
      }
    end
  end

  class ObjectDumper < Dumper
    def self.priority
      0
    end

    def self.can_dump?(_object)
      true
    end

    def dump
      ivars = object.instance_variables.map do |key|
        [key, Dumper.dump(object.instance_variable_get(key))]
      end.to_h

      {
        '__rjson_builder' => 'RJSON::ObjectBuilder',
        '__rjson_class_name' => object.class.name,
        **ivars
      }
    end
  end

  class DumperProxy < Dumper
    def self.priority
      1000
    end

    def self.can_dump?(object)
      object.respond_to?(:as_rjson)
    end

    def dump(object)
      self.class.dump(object.as_rjson)
    end
  end

  DUMPERS = Dumper.descendants.sort_by { |x| -x.priority }.freeze
end
