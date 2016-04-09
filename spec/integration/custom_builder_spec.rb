class CustomObject
  attr_accessor :foo, :bar

  def initialize(foo, bar)
    self.foo = foo
    self.bar = bar
  end

  def as_rjson(context)
    {
      '__rjson_builder' => 'CustomBuilder',
      '__rjson_option' => (foo if context.fetch(:save_foo, true)),
      ':data' => context.as_rjson(bar),
    }.compact
  end

  def ==(other)
    foo == other.foo && bar == other.bar
  end
end

class CustomBuilder
  attr_accessor :foo

  def initialize(option:)
    self.foo = option
  end

  def build(data:)
    CustomObject.new(foo, data)
  end
end

describe 'custom builder' do
  specify 'with empty context it works' do
    object = CustomObject.new(123, Set[1, 2, 3])
    expect(object).to receive(:as_rjson).and_call_original
    expect(RJSON.load(RJSON.dump(object))).to eq object
  end
end
