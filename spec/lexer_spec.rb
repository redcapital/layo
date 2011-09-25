require 'stringio'
require 'minitest/autorun'
require 'layo'

include Layo

describe Lexer do
  before do
    @lexer = Lexer.new
  end

  it 'should recognize special character lexemes' do
    lexemes = [Lexeme.new(',', 1, 2), Lexeme.new('!', 1, 4)]
    @lexer.scan(StringIO.new(' , !')).must_equal lexemes
  end
end
