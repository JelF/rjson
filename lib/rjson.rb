require 'active_support/all'

require 'rjson/version'
require 'rjson/errors'
require 'rjson/parser'
require 'rjson/dumpers'
require 'rjson/builders'

module RJSON
  ActiveSupport::Inflector.inflections do |inflect|
    inflect.acronym 'RJSON'
  end

  class << self
    def from_json(json_string)
      Parser.parse_json(json_string)
    end
    alias load from_json

    def to_json(object)
      Dumper.to_json(object)
    end
    alias dump to_json
  end
end
