require 'minitest/autorun'
require 'mocha'
require 'layo'

include Layo
include Layo::Ast

describe Parser do
  before do
    @tokenizer = Tokenizer.new(Lexer.new)
    @parser = Parser.new(@tokenizer)
  end

  it 'should parse main node' do
    @tokenizer.tokens = [
      {:type => :hai},
      {:type => :float, :data => 1.2},
      {:type => :newline},
      {:type => :eof}
    ]
    @parser.expects(:parse_block).returns(BlockNode.new)
    node = @parser.parse
    node.must_be_instance_of MainNode
    node.version.must_equal 1.2
    node.block.stmt_list.must_be_empty
  end
end
