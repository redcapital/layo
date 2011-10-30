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
    @tokenizer.stubs(:next_item).returns(
      {:type => :hai},
      {:type => :float, :data => 1.2},
      {:type => :newline},
      {:type => :eof}
    )
    @parser.expects(:parse_block).returns(BlockNode.new)
    node = @parser.parse
    node.must_be_instance_of MainNode
    node.version.must_equal 1.2
    node.block.stmt_list.must_be_empty
  end

  it "should parse block node" do
    statements = [StmtNode.new, StmtNode.new]
    @parser.stubs(:parse_stmt).returns(*statements)
    @parser.stubs(:stmt_next?).returns(true, true, false)
    node = @parser.parse_block
    node.must_be_instance_of BlockNode
    node.stmt_list.must_equal statements
  end

  describe "#parse_constant" do
    it "should parse boolean values" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :boolean, :data => true},
        {:type => :boolean, :data => false}
      )
      node = @parser.parse_constant
      node.must_be_instance_of ConstantNode
      node.value.must_equal true

      node = @parser.parse_constant
      node.must_be_instance_of ConstantNode
      node.value.must_equal false
    end

    it "should parse integer values" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :integer, :data => 567}
      )
      node = @parser.parse_constant
      node.must_be_instance_of ConstantNode
      node.value.must_equal 567
    end

    it "should parse float values" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :float, :data => -5.234}
      )
      node = @parser.parse_constant
      node.must_be_instance_of ConstantNode
      node.value.must_equal -5.234
    end

    it "should parse string values" do
      @tokenizer.stubs(:next_item).returns :type => :string, :data => 'some value'
      node = @parser.parse_constant
      node.must_be_instance_of ConstantNode
      node.value.must_equal 'some value'
    end
  end

  it "should parse identifier node" do
    @tokenizer.stubs(:next_item).returns :type => :identifier, :data => 'abc'
    node = @parser.parse_identifier
    node.must_be_instance_of IdentifierNode
    node.data.must_equal 'abc'
  end

  it "should parse type node" do
    [:troof, :yarn, :numbr, :numbar, :noob].each do |value|
      @tokenizer.stubs(:next_item).returns :type => value
      node = @parser.parse_type
      node.must_be_instance_of TypeNode
      node.data.must_equal value
    end
  end

  it "should parse cast stmt node" do
    identifier = IdentifierNode.new('abc')
    type = TypeNode.new(:troof)
    @parser.expects(:parse_identifier).returns(identifier)
    @parser.expects(:parse_type).returns(type)
    @tokenizer.stubs(:next_item).returns(
      {:type => :is_now_a}, {:type => :newline}
    )
    node = @parser.parse_cast_stmt
    node.must_be_instance_of CastStmtNode
    node.identifier.must_be_same_as identifier
    node.type.must_be_same_as type
  end

  describe "#parse_print_stmt" do
    it "should parse print stmt node with exclamation mark" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :visible}, {:type => :exclamation}, {:type => :newline}
      )
      expr = ExprNode.new
      @parser.expects(:parse_expr).returns(expr)
      @parser.stubs(:expr_next?).returns(false)
      node = @parser.parse_print_stmt
      node.must_be_instance_of PrintStmtNode
      node.expr_list.size.must_equal 1
      node.expr_list.first.must_be_same_as expr
      node.suppress.must_equal true
    end

    it "should parse print stmt node without exclamation mark" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :visible}, {:type => :newline}
      )
      exprs = [ExprNode.new, ExprNode.new]
      @parser.stubs(:parse_expr).returns(*exprs)
      @parser.stubs(:expr_next?).returns(true, false)
      node = @parser.parse_print_stmt
      node.must_be_instance_of PrintStmtNode
      node.expr_list.must_equal exprs
      node.suppress.must_equal false
    end
  end
end
