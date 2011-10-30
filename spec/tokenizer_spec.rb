require 'stringio'

require 'minitest/autorun'
require 'layo'

include Layo

describe Tokenizer do
  before do
    @lexer = Lexer.new(StringIO.new)
    @tokenizer = Tokenizer.new(@lexer)
  end

  it 'should recognize all plain tokens' do
    tokens = {}
    ['HAI', 'KTHXBYE', 'NOOB', 'TROOF', 'NUMBR', 'NUMBAR', 
      'YARN', 'I HAS A', 'ITZ', 'R', 'SUM OF', 'DIFF OF', 'PRODUKT OF',
      'QUOSHUNT OF', 'MOD OF', 'BIGGR OF', 'SMALLR OF', 'BOTH OF', 'EITHER OF',
      'WON OF', 'NOT', 'ALL OF', 'ANY OF', 'BOTH SAEM', 'DIFFRINT',
      'SMOOSH', 'MAEK', 'IS NOW A', 'A', 'VISIBLE', 'GIMMEH', 'MKAY', 'AN',
      'O RLY?', 'YA RLY', 'NO WAI', 'MEBBE', 'OIC', 'WTF?', 'OMG', 'OMGWTF',
      'GTFO', 'IM IN YR', 'YR', 'TIL', 'WILE', 'IM OUTTA YR', 'UPPIN',
      'NERFIN', 'HOW DUZ I', 'AN YR', 'IF U SAY SO', 'FOUND YR'
    ].each { |t| tokens[t.gsub(' ', '_').downcase.to_sym] = t.split(' ') }
    tokens.each do |type, value|
      # Assign line number and position to each lexeme
      value.map! { |item| [item, 1, 1] }
      lexer = Lexer.new(StringIO.new)
      lexer.stubs(:next_item).returns(*value)
      @tokenizer.lexer = lexer
      @tokenizer.next[:type].must_equal type
    end
  end

  it 'should recognize newline tokens' do
    @lexer.stubs(:next_item).returns(["\n", 1, 1])
    @tokenizer.next[:type].must_equal :newline
  end

  it' should recognize exclamation mark token' do
    @lexer.stubs(:next_item).returns ['!', 1, 1]
    @tokenizer.next[:type].must_equal :exclamation
  end

  it 'should recognize string tokens' do
    @lexer.stubs(:next_item).returns ['"some string lexeme"', 1, 1]
    token = @tokenizer.next
    token[:type].must_equal :string
    token[:data].must_equal 'some string lexeme'
  end

  it 'should recognize float tokens' do
    [0.255, -1234.02].each do |number|
      @lexer.stubs(:next_item).returns [number.to_s, 1, 1]
      token = @tokenizer.next
      token[:type].must_equal :float
      token[:data].must_equal number
    end
  end

  it 'should recognize integer tokens' do
    [25, -9, 0].each do |number|
      @lexer.stubs(:next_item).returns [number.to_s, 1, 1]
      token = @tokenizer.next
      token[:type].must_equal :integer
      token[:data].must_equal number
    end
  end

  it 'should recognize boolean tokens' do
    ['WIN', 'FAIL'].each do |value|
      @lexer.stubs(:next_item).returns [value, 1, 1]
      token = @tokenizer.next
      token[:type].must_equal :boolean
      token[:data].must_equal (value == 'WIN')
    end
  end

  it 'should recognize identifier tokens' do
    ['layo', 'lAYO123', 'Layo_layo_3'].each do |value|
      @lexer.stubs(:next_item).returns [value, 1, 1]
      token = @tokenizer.next
      token[:type].must_equal :identifier
      token[:data].must_equal value
    end
  end

  it 'should return eof token if lexeme is nil' do
    @lexer.stubs(:next_item).returns [nil, 1, 1]
    @tokenizer.next[:type].must_equal :eof
  end

  it 'should raise exception if token is unknown' do
    ['abc:', '%sdf', '- 25', '-', '.333'].each do |value|
      @lexer.stubs(:next_item).returns [value, 1, 1]
      lambda { @tokenizer.next }.must_raise Layo::UnknownTokenError
    end
  end

  it 'should consume all lexemes of multi-lexeme token' do
    @lexer.stubs(:next_item).returns(['ALL', 1, 1], ['OF', 1, 1], ['NOOB', 1, 1])
    @tokenizer.next[:type].must_equal :all_of
    @tokenizer.next[:type].must_equal :noob
  end
end
