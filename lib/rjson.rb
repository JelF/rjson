require 'active_support/all'

require 'rjson/version'
require 'rjson/errors'

module RJSON
  autoload :Parser, 'rjson/parser'

  def self.from_json(json_string)
    Parser.parse_json(json_string)
  end
end
