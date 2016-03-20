describe 'serialziing does not change' do
  def expect_intactness(value)
    expect(RJSON.load(RJSON.dump(value))).to eq(value)
  end

  specify Integer do
    expect_intactness(0)
    expect_intactness(123)
    expect_intactness(213120412394214321213321423542323432412341254125123532123)
  end

  specify Float do
    expect_intactness(0.0)
    expect_intactness(12.3)
    expect_intactness(21345123412341242.21341231234214512)
    expect_intactness(Float::INFINITY)
  end

  specify BigDecimal do
    expect_intactness(BigDecimal(0))
    expect_intactness(BigDecimal(123))
    expect_intactness(BigDecimal(123124232353214543253245324))
    expect_intactness(BigDecimal(12312423235321.4543253245324, 10))
  end

  specify Complex do
    expect_intactness(0i)
    expect_intactness(5i)
    expect_intactness(1 + 5i)
    expect_intactness(1.2 + 5.6i)
    expect_intactness(124412412412345123412.214321 + 5.24125412512353252353251i)
    expect_intactness(124412412412345123412.214321 + 1i / 3)
  end

  specify Rational do
    expect_intactness(Rational(0, 1))
    expect_intactness(Rational(152145213421312312, 354135213421421421))
    expect_intactness(Rational(12521352345432523454325432, 123412421))
  end

  specify 'booleans and nil' do
    expect_intactness(false)
    expect_intactness(true)
    expect_intactness(nil)
  end

  specify Array do
    expect_intactness([])
    expect_intactness([1, 2, 3])
  end

  specify Hash do
    expect_intactness({})
    expect_intactness(foo: :bar)
    expect_intactness('foo' => :bar)
    expect_intactness(':foo' => :bar)
    expect_intactness(1 => 2, 3 => 4, foo: 1242151251235123)
    expect_intactness(Rational(1, 5) => true)
  end

  specify Object do
    # Set is a generic object, i am not lying
    expect_intactness(Set[])
    expect_intactness(Set[1, 2, 3])
    expect_intactness(Set[0, 1i, 1 + 1i])
  end
end
