require 'active_support/all'

require 'rjson/version'
require 'rjson/errors'
require 'rjson/parser'
require 'rjson/dumpers'
require 'rjson/builders'

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
    # @param object
    #   generic object
    # @return [String] valid json string
    def to_json(object)
      Dumper.to_json(object)
    end
    alias_method :dump, :to_json
  end
end
