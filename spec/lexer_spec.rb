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

    it 'should raise a syntax error when there is not subsequent line' do
      @lexer.input = StringIO.new("abc...\n")
      @lexer.next
      lambda { @lexer.next }.must_raise Layo::SyntaxError
    end
  end

  describe 'when sees BTW' do
    it 'should treat everything till the end of line as a comment' do
      @lexer.input = StringIO.new("abc BTW it's comment")
      @lexer.next.must_equal ['abc', 1, 1]
      # Newline should be added
      @lexer.next[0].must_equal "\n"
      @lexer.next[0].must_be_nil
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

    it 'should raise a syntax error when there is not TLDR' do
      @lexer.input = StringIO.new('OBTW
        comment. no tldr
      ')
      lambda { @lexer.next }.must_raise Layo::SyntaxError
    end
  end

  describe 'when sees double quotation marks (")' do
    it 'should treat everything till another " character as a string lexeme' do
      @lexer.input = StringIO.new('"hello world"')
      @lexer.next.must_equal ['"hello world"', 1, 1]
    end

    it 'should treat :" as an escape character' do
      @lexer.input = StringIO.new('"hello :" world"')
      @lexer.next.must_equal ['"hello :" world"', 1, 1]
    end

    it 'should handle empty string' do
      @lexer.input = StringIO.new('""')
      @lexer.next.must_equal ['""', 1, 1]
    end

    it 'should raise a syntax error if string is unterminated' do
      @lexer.input = StringIO.new(' "bla bla bla ')
      lambda { @lexer.next }.must_raise Layo::SyntaxError
    end

    it 'should raise a syntax error if string terminator is not followed by allowed delimiter' do
      @lexer.input = StringIO.new('"a","b" "c"!"d"...
"e"…
"f"
"g"bla')
      # OK, since "a" is followed by a ','
      @lexer.next.must_equal ['"a"', 1, 1]
      @lexer.next.must_equal ["\n", 1, 4]
      # OK, since "b" is followed by a space
      @lexer.next.must_equal ['"b"', 1, 5]
      # OK, since "c" is followed by a '!'
      @lexer.next.must_equal ['"c"', 1, 9]
      @lexer.next.must_equal ['!', 1, 12]
      # OK, since "d" is followed by a '...'
      @lexer.next.must_equal ['"d"', 1, 13]
      # OK, since "e" is followed by a '…'
      @lexer.next.must_equal ['"e"', 2, 1]
      # OK, since "f" is followed by a newline
      @lexer.next.must_equal ['"f"', 3, 1]
      @lexer.next.must_equal ["\n", 3, 4]
      # Error, since "g" is not followed by any allowed delimiter
      lambda { @lexer.next }.must_raise Layo::SyntaxError
    end
  end
end
