module RJSON
  # Generic dumper superclass.
  # Dumpers are used to dump generic object into rjson.
  # In most cases, you can basicaly define `#as_rjson` to do it.
  class Dumper
    # @api private
    # @see DUMPERS
    # Used to try specific dumpers before more common
    def self.priority
      500
    end

    # Converts generic object to rjson
    # @param object generic object
    # @return [String] json string within rjson data inside
    def self.to_json(object)
      dump(object).to_json
    end

    # @api private
    # Converts generic object to unconverted json, so it could be placed
    # inside a hash/array without double conversion to json
    # @param object generic object
    # @return [Hash, Array, String, Integer] rjson data without json encoding
    def self.dump(object)
      return object.as_rjson if object.respond_to?(:as_rjson)
      choose_object_dumper(object).new(object).dump
    end

    # @api private
    # @see DUMPERS
    # Selects dumper to dump object
    # @return [Class(RJSON::Dumper)] first dumper accepted object
    def self.choose_object_dumper(object)
      DUMPERS.find { |x| x.can_dump?(object) }
    end

    # @api private
    # Default implementation
    # @return true if object could be dumped
    # @return false otherwise
    def self.can_dump?(_object)
      false
    end

    # @param object to dump
    def initialize(object)
      self.object = object
    end

    private

    # Object being dumped
    attr_accessor :object

    # Direct call to dump object as hash, oftenly used to encode builders data
    # Keys are symbolized to use with **interpolation
    # @param hash [Hash]
    # @return [Hash(Symbol => Object)] rjson hash
    def dump_hash(hash)
      # Symbolizing keys to unlock **intepolation
      ObjectDumper.dump(hash).symbolize_keys
    end
  end

  # Dumper, used when we don't realy want to comvert something
  class PrimitiveTypesDumper < Dumper
    # @api private
    # checks if object could be converted without changes
    # @param object
    # @return true if object could be dumped
    # @return false otherwise
    def self.can_dump?(object)
      object.class.in?([Integer, Fixnum, Bignum]) ||
        object.in?([true, false, nil])
    end

    # returns object intact
    # @return object intact
    def dump
      object
    end
  end

  # Dumper mainly used to handle Float::INFINITY
  class FloatDumper < Dumper
    # @api private
    # checks if object is a float
    # @param object
    # @return true if object is Float
    # @return false otherwise
    def self.can_dump?(object)
      object.class == Float
    end

    # @return [Float] uncanged if it is finit
    # @return [Hash(Symbol => Object)] rjson hash representing Float::Infinity
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

  # Prepends string by '%' to avoid any collisions and also make
  # all dumped strings similar
  class StringDumper < Dumper
    # @api private
    # checks if object is a String
    # @param object
    # @return true if object is a String
    # @return false otherwise
    def self.can_dump?(object)
      object.class == String
    end

    # @return [String] object, prepended by '%'
    def dump
      "%#{object}"
    end
  end

  # Prepends symbol by ':'
  class SymbolDumper < Dumper
    # @api private
    # checks if object is a symbol
    # @param object
    # @return true if object is a Symbol
    # @return false otherwise
    def self.can_dump?(object)
      object.class == Symbol
    end

    # @return [Symbol] object, prepended by ':'
    def dump
      ":#{object}"
    end
  end

  # Dumps everything inside array
  class ArrayDumper < Dumper
    # @api private
    # checks if object is an Array
    # @param object
    # @return true if object is an Array
    # @return false otherwise
    def self.can_dump?(object)
      object.class == Array
    end

    # @return [Array]
    def dump
      object.map { |x| self.class.dump(x) }
    end
  end

  # Dumps both keys and values of hash
  class HashDumper < Dumper
    # @api private
    # checks if object is a Hash
    # @param object
    # @return true if object is a Hash
    # @return false otherwise
    def self.can_dump?(object)
      object.class == Hash
    end

    # converts both keys and values, using '!' directive for keys if needed
    # @return Hash
    def dump
      object.map do |key, value|
        dumped_key = self.class.dump(key)
        dumped_key = "!#{dumped_key.to_json}" unless dumped_key.is_a?(String)
        [dumped_key, self.class.dump(value)]
      end.to_h
    end
  end

  # Converts values, that could be represented by string
  # (rational, big decimal and complex values)
  class StringRepresentableDumper < Dumper
    # @api private
    # checks if object could be represented by string
    # @param object
    # @return true if object could be represented by string
    # @return false otherwise
    def self.can_dump?(object)
      object.class.in?([BigDecimal, Complex, Rational])
    end

    # This section of code is useless, unless `.can_dump?` would be changed.
    #
    # def namespace
    #   namespace_name = object.class.name.deconstantize
    #   return if namespace_name.blank?
    #
    #   {
    #     '__rjson_builder' => 'RJSON::ConstantLoader',
    #     **dump_hash(name: namespace_name)
    #   }
    # end

    # @see RJSON::FunctionalBuilder
    # directly provides data for `RJSON::FunctionalBuilder`
    # @return [Hash]
    def dump
      {
        '__rjson_builder' => 'RJSON::FunctionalBuilder',
        **dump_hash(method: object.class.name, args: [object.to_s])
      }
    end
  end

  # Dumps ivars and class of object
  class ObjectDumper < Dumper
    # @api private
    # @see DUMPERS
    # This dumper should be used if no other matched
    def self.priority
      0
    end

    # @api private
    # @return true
    def self.can_dump?(_object)
      true
    end

    # @see RJSON::ObjectBuilder
    # directly provides data for `RJSON::ObjectBuilder`
    # @return [Hash]
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

  # This dumper uses `#as_rjson` if method specified
  class DumperProxy < Dumper
    # @api private
    # @see DUMPERS
    # This dumper should be used with any [#as_rjson] object
    def self.priority
      1000
    end

    # @api private
    # @param object
    # @return true if object repsond_to #as_rjson
    def self.can_dump?(object)
      object.respond_to?(:as_rjson)
    end

    # Calls object#as_rjson
    # @param object [#as_rjson]
    def dump(object)
      object.as_rjson
    end
  end

  # @api private
  # Collects all dumpers defined in 'rjson/dumpers' and sorts them
  # by their priority
  DUMPERS = Dumper.descendants.sort_by { |x| -x.priority }.freeze
end
