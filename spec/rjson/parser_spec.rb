describe RJSON::Parser do
  def parse(value, raw = false)
    value = value.to_json unless raw
    described_class.parse_json(value)
  end

  def expect_parse(value, raw = false)
    expect(parse(value, raw))
  end

  it 'proxies yaml errors' do
    original_error = StandardError.new('original message')
    data = double(:data)
    expect(YAML).to receive(:load).with(data).and_raise(original_error)

    begin
      parse(data, true)
    rescue => e
      expect(e).to be_a(RJSON::YAMLParserError)
      expect(e.message).to eq 'original message'
      expect(e.original_error).to eq original_error
    else
      raise 'no error throwed'
    end
  end

  it 'lefts primitive types intact' do
    expect_parse('123', true).to eq 123
    expect_parse('null', true).to be_nil
  end

  it 'back-compatible with yaml' do
    expect_parse(Set[1, 2, 3].to_yaml, true).to eq Set[1, 2, 3]
  end

  describe 'strings' do
    it 'lefts regular strings intact' do
      expect_parse('foo').to eq 'foo'
    end

    it "converts strings to symbols, if they are prefixed with ':'" do
      expect_parse(':foo').to eq :foo
    end

    it "removes single '%' in begining of string" do
      expect_parse('%foo').to eq 'foo'
      expect_parse('%:foo').to eq ':foo'
      expect_parse('%%foo').to eq '%foo'
    end

    it "reads json data from string, starting with '!'" do
      expect_parse('!"foo"').to eq 'foo'
      expect_parse('!":foo"').to eq :foo
      expect_parse('!{"foo": "bar"}').to eq('foo' => 'bar')
    end
  end

  it 'converts arrays contents' do
    expect_parse(['foo', ':bar', 123, nil]).to eq ['foo', :bar, 123, nil]
  end

  describe 'hashes' do
    it 'converts keys' do
      expect_parse(':foo' => true, '%:bar' => false)
        .to eq(foo: true, ':bar' => false)
    end

    it 'converts values' do
      expect_parse('foo' => { 'bar' => 123 })
        .to eq('foo' => { 'bar' => 123 })
    end

    it 'allows private namespace strings to be keys, if they are prefixed' do
      expect_parse('%__rjson_builder' => nil).to eq('__rjson_builder' => nil)
      expect_parse(':__rjson_builder' => nil).to eq(__rjson_builder: nil)
    end

    it 'raises error, if unprefixed private namespace string is a key, but ' \
       'no builder specified' do
      begin
        parse('__rjson_foo' => 'bar')
      rescue => e
        expect(e).to be_a(RJSON::PrivateKeysNotUsed)
        expect(e.message)
          .to start_with 'Private keys ["__rjson_foo"] not used in'
        expect(e.backtrace[0]).to include 'rjson/parser'
        expect(e.backtrace[0]).to include 'parse_hash'
      else
        raise 'no error throwed'
      end
    end

    context 'with builder' do
      let(:builder_instance) { double(:builder_instance) }
      let(:builder) { double(:builder) }
      let(:builder_string) do
        ''.tap do |builder_string|
          allow(builder_string).to receive(:constantize).and_return(builder)
        end
      end

      it 'calls builder with options' do
        data = {
          '__rjson_builder' => builder_string,
          '__rjson_arg' => 'generic argument',
          ':key' => '%:value'
        }

        expect(builder).to(receive(:new).with(arg: 'generic argument')
                            .and_return(builder_instance))
        expect(builder_instance).to receive(:build).with(key: ':value')

        # Don't use parse_json to allow mocks work
        described_class.parse_generic(data)
      end

      it 'proxies builder load erros' do
        begin
          parse('__rjson_builder' => 'RJSON::UnknownBuilder')
        rescue => e
          expect(e).to be_a(RJSON::ObjectLoadError)
          expect(e.original_error).to be_a(NameError)
        else
          raise 'no error throwed'
        end
      end

      it 'proxies builder argument errors' do
        begin
          parse('__rjson_builder' => 'RJSON::ObjectBuilder')
        rescue => e
          expect(e).to be_a(RJSON::ProxyError)
          expect(e.original_error).to be_a(ArgumentError)
        else
          raise 'no error throwed'
        end
      end
    end
  end
end
