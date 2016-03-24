module RJSON
  # Contains some context, which could be used from dumpers to handle
  # specific options. For example, you want to dump all AR records as global ids
  # so you specify CoderContext.new(ar_as_global_id: true)
  class CoderContext
    delegate :[], :[]=, to: :data
    delegate :load, to: RJSON

    # @param data [Hash]
    def initialize(data = {})
      self.data = data.with_indifferent_access
    end

    # @param another_context [CoderContext]
    def merge(another_context)
      CoderContext.new(data.merge(another_context.data))
    end

    # @see RJSON.dump
    # Dumps generic object into a valid json string
    # @param object generic object
    # @return [String] valid json string
    def dump(object)
      RJSON.dump(object, self)
    end

    protected

    # data hash with indifferent access
    attr_accessor :data
  end
end
