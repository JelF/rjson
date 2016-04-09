require 'active_support/all'

require 'rjson/version'
require 'rjson/errors'
require 'rjson/parser'
require 'rjson/dumpers'
require 'rjson/builders'
require 'rjson/coder_context'

# ==RJSON
# RJSON describes RJSON (Ruby JSON) serializer and RJSON format.
# Usage: `RJSON.dump(object)`, then `RJSON.load(string_with_dump)`
# Constraint (specified in sepc/rjson/intactness_spec):
# `RJSON.load(RJSON.dump(x)) == x`
module RJSON
  ActiveSupport::Inflector.inflections do |inflect|
    inflect.acronym 'RJSON'
  end

  class << self
    # Restores generic object from dump, possibly calling any function
    # in process and other things with bad security
    # @param json_string [STRING]
    #   possibly, any correct rjson, json or even yaml string.
    # @raise [RJSON::ParseError]
    # @return generic object
    # @return nil if json_string is also nil
    def from_json(json_string)
      Parser.parse_json(json_string)
    end
    alias_method :load, :from_json

    # Dumps generic object into a valid json string
    # @param object generic object
    # @param context [RJONS::CoderContext] context in which dump will be made
    # @param context [Hash] data from which context would be generated
    # @return [String] valid json string
    def to_json(object, context = CoderContext.new)
      context = CoderContext.new(context) if context.is_a?(Hash)
      Dumper.to_json(object, context)
    end
    alias_method :dump, :to_json

    private

    # Default context would be used
    def null_context
      CoderContext.new
    end
  end
end

# @see RJSON::CoderContext
# RJSON function is RJSON::CoderContext.new alias
# Usage: `serialize :column, RJSON(foo: :bar)`
# @param hash [Hash] context coder would use
# @return [RJSON::CoderContext]
def RJSON(hash = {}) # rubocop:disable Style/MethodName
  RJSON::CoderContext.new(hash)
end
