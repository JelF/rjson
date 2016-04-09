require 'integration/database_context'

class SerializationSpecDummy < ActiveRecord::Base
  serialize :column, RJSON
end

class SerializationSpecDummy2 < ActiveRecord::Base
  self.table_name = :serialization_spec_dummies
  serialize :column, RJSON(foo: :bar)
end

describe 'serialization', :database do
  let(:schema) { <<-SQL }
    CREATE TABLE serialization_spec_dummies (
      id INTEGER PRIMARY KEY,
      column STRING
    );
  SQL

  shared_context 'it saves and loads hash with generic data' do |klass, column|
    context klass do
      it 'saves and loads hash with generic data' do
        data = { (1 + 1i) => true, foo: { bar: 123 }, 500 => Set[1, 2, 3] }
        new_record_id = klass.create!(column => data).id
        expect(klass.find(new_record_id).public_send(column)).to eq data
      end
    end
  end

  it_behaves_like 'it saves and loads hash with generic data',
                  SerializationSpecDummy, :column

  it_behaves_like 'it saves and loads hash with generic data',
                  SerializationSpecDummy2, :column
end
