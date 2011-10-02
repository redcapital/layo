# encoding: UTF-8

require 'stringio'
require 'minitest/autorun'
require 'layo'

include Layo

describe Lexer do
  before do
    @lexer = Lexer.new
  end

  it 'should transform all line-ending characters to \n' do
    str = "\n \r\n \r "
    @lexer.input = StringIO.new(str)
    @lexer.next.must_equal ["\n", 1, 1]
    @lexer.next.must_equal ["\n", 2, 2]
    @lexer.next.must_equal ["\n", 3, 2]
  end

  it 'should recognize lexemes separated by whitespaces' do
    @lexer.input = StringIO.new("abc  def   \t\tghi")
    @lexer.next.must_equal ['abc', 1, 1]
    @lexer.next.must_equal ['def', 1, 6]
    @lexer.next.must_equal ['ghi', 1, 14]
  end

  it 'should recognize lexemes separated by newlines' do
    @lexer.input = StringIO.new("abc\rdef\nghi")
    @lexer.next.must_equal ['abc', 1, 1]
    @lexer.next.must_equal ["\n", 1, 4]
    @lexer.next.must_equal ['def', 2, 1]
    @lexer.next.must_equal ["\n", 2, 4]
    @lexer.next.must_equal ['ghi', 3, 1]
  end

  it 'should recognize special character lexemes' do
    @lexer.input = StringIO.new("abc! ,def ,")
    @lexer.next.must_equal ['abc', 1, 1]
    @lexer.next.must_equal ['!', 1, 4]
    # Comma acts as a virtual newline or a soft-command-break
    @lexer.next.must_equal ["\n", 1, 6]
    @lexer.next.must_equal ['def', 1, 7]
    @lexer.next.must_equal ["\n", 1, 11]
  end

  describe 'when sees line ending with triple dots' do
    it 'should join subsequent non-empty line' do
      @lexer.input = StringIO.new("abc...\ndef…\nghi")
      @lexer.next.must_equal ['abc', 1, 1]
      @lexer.next.must_equal ['def', 2, 1]
      @lexer.next.must_equal ['ghi', 3, 1]
    end

    it 'should raise a syntax error when the subsequent line is empty' do
      @lexer.input = StringIO.new("abc...\n  \n")
      @lexer.next
      lambda { @lexer.next }.must_raise Layo::SyntaxError
    end
  end

  describe 'when sees BTW' do
    it 'should treat everything till the end of line as a comment' do
      @lexer.input = StringIO.new("abc BTW it's comment")
      @lexer.next.must_equal ['abc', 1, 1]
      @lexer.next.must_be_nil
    end
  end

  describe 'when sees OBTW' do
    it 'should treat all lines until TLDR as a comment' do
      @lexer.input = StringIO.new("ABC
OBTW this is a long comment block
      see, i have more comments here
      and here
TLDR
DEF")
      @lexer.next.must_equal ['ABC', 1, 1]
      @lexer.next.must_equal ["\n", 1, 4]
      @lexer.next.must_equal ["\n", 5, 5]
      @lexer.next.must_equal ['DEF', 6, 1]
    end

    it 'should recognize commands before OBTW and after TLDR' do
      @lexer.input = StringIO.new("ABC, OBTW
        this is comment
        valid comment
TLDR, DEF")
      @lexer.next.must_equal ['ABC', 1, 1]
      @lexer.next.must_equal ["\n", 1, 4]
      @lexer.next.must_equal ['DEF', 4, 7]
    end
  end
end
