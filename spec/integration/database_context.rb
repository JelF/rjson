require 'active_record'

shared_context 'with database support', :database do
  let(:schema) { '' }
  around do |block|
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3',
                                            database: ':memory:')

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(schema)
      block.call
    end
  end
end
