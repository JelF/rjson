require 'integration/database_context'

class SerializationSpecDummy < ActiveRecord::Base
  serialize :column, RJSON
end

describe SerializationSpecDummy, :database do
  let(:schema) { <<-SQL }
    CREATE TABLE serialization_spec_dummies (
      id INTEGER PRIMARY KEY,
      column STRING
    );
  SQL

  it 'saves and loads hash with generic data' do
    data = { (1 + 1i) => true, foo: { bar: 123 }, 500 => Set[1, 2, 3] }
    new_record_id = SerializationSpecDummy.create!(column: data).id
    expect(SerializationSpecDummy.find(new_record_id).column).to eq data
  end
end
