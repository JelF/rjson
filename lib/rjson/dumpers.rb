module RJSON
  # Generic dumper superclass.
  # Dumpers are used to dump generic object into rjson.
  # In most cases, you can basicaly define `#as_rjson` to do it.
  class Dumper
    # Converts generic object to rjson
    # @param object generic object
    # @param context [RJSON::CoderContext]
    # @return [String] json string within rjson data inside
    def self.to_json(object, context)
      dump(object, context).to_json
    end

    # @api private
    # Converts generic object to unconverted json, so it could be placed
    # inside a hash/array without double conversion to json
    # @param object generic object
    # @param context [RJSON::CoderContext]
    # @return [Hash, Array, String, Integer] rjson data without json encoding
    def self.dump(object, context)
      DUMPERS.map { |dumper| dumper.new(object, context) }
             .sort_by { |x| -x.priority }.find(&:can_dump?).dump
    end

    # @param object to dump
    # @param context [RJSON::CoderContext]
    def initialize(object, context)
      self.object = object
      self.context = context
    end

    # Default implementation
    # @return true if object could be dumped
    # @return false otherwise
    def can_dump?
      false
    end

    # @see RJSON::Dumper.dump
    # Used to try specific dumpers before more common
    def priority
      500
    end

    private

    # Object being dumped
    attr_accessor :object
    # RJSON::CoderContext instance
    attr_accessor :context

    # Direct call to dump object as hash, oftenly used to encode builders data
    # Keys are symbolized to use with **interpolation
    # @param hash [Hash]
    # @return [Hash(Symbol => Object)] rjson hash
    def dump_hash(hash, context = CoderContext.new)
      # Symbolizing keys to unlock **intepolation
      ObjectDumper.dump(hash, context).symbolize_keys
    end
  end

  # Dumper, used when we don't realy want to comvert something
  class PrimitiveTypesDumper < Dumper
    # checks if object could be converted without changes
    # @return true if object could be dumped
    # @return false otherwise
    def can_dump?
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
    # checks if object is a float
    # @return true if object is Float
    # @return false otherwise
    def can_dump?
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
    # checks if object is a String
    # @return true if object is a String
    # @return false otherwise
    def can_dump?
      object.class == String
    end

    # @return [String] object, prepended by '%'
    def dump
      "%#{object}"
    end
  end

  # Prepends symbol by ':'
  class SymbolDumper < Dumper
    # checks if object is a symbol
    # @return true if object is a Symbol
    # @return false otherwise
    def can_dump?
      object.class == Symbol
    end

    # @return [Symbol] object, prepended by ':'
    def dump
      ":#{object}"
    end
  end

  # Dumps everything inside array
  class ArrayDumper < Dumper
    # checks if object is an Array
    # @return true if object is an Array
    # @return false otherwise
    def can_dump?
      object.class == Array
    end

    # @return [Array]
    def dump
      object.map { |x| self.class.dump(x, context) }
    end
  end

  # Dumps both keys and values of hash
  class HashDumper < Dumper
    # checks if object is a Hash
    # @return true if object is a Hash
    # @return false otherwise
    def can_dump?
      object.class == Hash
    end

    # converts both keys and values, using '!' directive for keys if needed
    # @return Hash
    def dump
      object.map do |key, value|
        dumped_key = self.class.dump(key, context)
        dumped_key = "!#{dumped_key.to_json}" unless dumped_key.is_a?(String)
        [dumped_key, self.class.dump(value, context)]
      end.to_h
    end
  end

  # Converts values, that could be represented by string
  # (rational, big decimal and complex values)
  class StringRepresentableDumper < Dumper
    # checks if object could be represented by string
    # @return true if object could be represented by string
    # @return false otherwise
    def can_dump?
      object.class.in?([BigDecimal, Complex, Rational])
    end

    # This section of code is useless, unless `#can_dump?` would be changed.
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
    # @see RJSON::Dumper.dump
    # This dumper should be used if no other matched
    def priority
      0
    end

    # @return true
    def can_dump?
      true
    end

    # @see RJSON::ObjectBuilder
    # directly provides data for `RJSON::ObjectBuilder`
    # @return [Hash]
    def dump
      ivars = object.instance_variables.map do |key|
        [key, Dumper.dump(object.instance_variable_get(key), context)]
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
    # @see RJSON::Dumper.dump
    # This dumper should be used with any [#as_rjson] object
    def priority
      1000
    end

    # @return true if object repsond_to #as_rjson
    def can_dump?
      object.respond_to?(:as_rjson)
    end

    # Calls object#as_rjson
    def dump
      object.as_rjson(object, context)
    end
  end

  # @api private
  # Collects all dumpers defined in 'rjson/dumpers' and sorts them
  # by their priority
  DUMPERS = Dumper.descendants.freeze
end
