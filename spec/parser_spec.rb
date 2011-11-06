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

  it "should parse input stmt node" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :gimmeh}, {:type => :newline}
    )
    identifier = IdentifierNode.new('abc')
    @parser.expects(:parse_identifier).returns(identifier)
    node = @parser.parse_input_stmt
    node.must_be_instance_of InputStmtNode
    node.identifier.must_be_same_as identifier
  end

  it "should parse assignment stmt node" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :r}, {:type => :newline}
    )
    identifier = IdentifierNode.new('abc')
    expr = ExprNode.new
    @parser.expects(:parse_identifier).returns(identifier)
    @parser.expects(:parse_expr).returns(expr)
    node = @parser.parse_assignment_stmt
    node.must_be_instance_of AssignmentStmtNode
    node.identifier.must_be_same_as identifier
    node.expr.must_be_same_as expr
  end

  describe "#parse_declaration_stmt" do
    it "should parse declaration stmt node without initialization" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :i_has_a}, {:type => :newline}
      )
      identifier = IdentifierNode.new('abc')
      @parser.expects(:parse_identifier).returns(identifier)
      node = @parser.parse_declaration_stmt
      node.must_be_instance_of DeclarationStmtNode
      node.identifier.must_be_same_as identifier
      node.initialization.must_be_nil
    end

    it "should parse declaration stmt node with initialization" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :i_has_a}, {:type => :itz}, {:type => :newline}
      )
      identifier = IdentifierNode.new('abc')
      init = ExprNode.new
      @parser.expects(:parse_identifier).returns(identifier)
      @parser.expects(:parse_expr).returns(init)
      node = @parser.parse_declaration_stmt
      node.must_be_instance_of DeclarationStmtNode
      node.identifier.must_be_same_as identifier
      node.initialization.must_be_same_as init
    end
  end

  describe "#parse_if_then_else" do
    before do
      @tokenizer_expectation = @tokenizer.stubs(:next_item).returns(
        {:type => :o_rly?}, {:type => :newline},
        {:type => :ya_rly}, {:type => :newline}
      )
      @block = BlockNode.new
      @parser_expectation = @parser.stubs(:parse_block).returns(@block)
    end

    it "should parse if then else stmt node without else's" do
      @tokenizer_expectation.then.returns({:type => :oic}, {:type => :newline})
      @parser.stubs(:elseif_next?).returns(false)
      node = @parser.parse_if_then_else_stmt
      node.must_be_instance_of IfThenElseStmtNode
      node.block.must_be_same_as @block
      node.elseif_list.must_be_empty
      node.else_block.must_be_nil
    end

    it "should parse if then else stmt node with else and elseif's" do
      @tokenizer_expectation.then.returns(
        {:type => :no_wai}, {:type => :newline},
        {:type => :oic}, {:type => :newline}
      )
      @parser.stubs(:elseif_next?).returns(true, true, false)
      elseif_list = [
        ElseIf.new(ExprNode.new, BlockNode.new),
        ElseIf.new(ExprNode.new, BlockNode.new)
      ]
      @parser.stubs(:parse_elseif).returns(*elseif_list)
      else_block = BlockNode.new
      @parser_expectation.then.returns(else_block)

      node = @parser.parse_if_then_else_stmt

      node.must_be_instance_of IfThenElseStmtNode
      node.block.must_be_same_as @block
      node.elseif_list.must_equal elseif_list
      node.else_block.must_be_same_as else_block
    end
  end

  it "should parse elseif" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :mebbe}, {:type => :newline}
    )
    block = BlockNode.new
    expr = ExprNode.new
    @parser.expects(:parse_block).returns(block)
    @parser.expects(:parse_expr).returns(expr)
    node = @parser.parse_elseif
    node.must_be_instance_of ElseIf
    node.block.must_be_same_as block
    node.expr.must_be_same_as expr
  end

  it "should parse switch stmt node" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :wtf?}, {:type => :newline}, {:type => :omgwtf}, 
      {:type => :newline}, {:type => :oic}, {:type => :newline}
    )
    cases = [mock(), mock()]
    default_case = BlockNode.new
    @parser.stubs(:parse_case).returns(*cases)
    @parser.stubs(:case_next?).returns(true, false)
    @parser.expects(:parse_block).returns(default_case)
    node = @parser.parse_switch_stmt
    node.must_be_instance_of SwitchStmtNode
    node.case_list.must_equal cases
    node.default_case.must_be_same_as default_case
  end

  it "should parse case" do
    @tokenizer.stubs(:next_item).returns({:type => :omg}, {:type => :newline})
    expr, block = mock(), mock()
    @parser.expects(:parse_expr).returns(expr)
    @parser.expects(:parse_block).returns(block)
    node = @parser.parse_case
    node.must_be_instance_of Case
    node.expr.must_be_same_as expr
    node.block.must_be_same_as block
  end

  it "should parse break stmt" do
    @tokenizer.stubs(:next_item).returns({:type => :gtfo}, {:type => :newline})
    node = @parser.parse_break_stmt
    node.must_be_instance_of BreakStmtNode
  end

  it "should parse return stmt node" do
    @tokenizer.stubs(:next_item).returns({:type => :found_yr}, {:type => :newline})
    expr = mock()
    @parser.expects(:parse_expr).returns(expr)
    node = @parser.parse_return_stmt
    node.must_be_instance_of ReturnStmtNode
    node.expr.must_be_same_as expr
  end

  describe "#parse_loop_stmt" do
    before do
      @tokenizer.stubs(:next_item).returns(
        {:type => :im_in_yr, :line => 1, :pos => 1}, {:type => :newline},
        {:type => :im_outta_yr}, {:type => :newline}
      )
    end

    it "should parse loop stmt node" do
      loop_update, loop_guard = mock(), mock()
      label = IdentifierNode.new('foo')
      @parser.stubs(:parse_identifier).returns(label, label)
      @parser.expects(:loop_update_next?).returns(true)
      @parser.expects(:loop_guard_next?).returns(true)
      @parser.expects(:parse_loop_update).returns(loop_update)
      @parser.expects(:parse_loop_guard).returns(loop_guard)
      node = @parser.parse_loop_stmt
      node.must_be_instance_of LoopStmtNode
      node.label.must_be_same_as label
      node.loop_update.must_be_same_as loop_update
      node.loop_guard.must_be_same_as loop_guard
    end

    it "should raise exception if label's are not equal" do
      a, b = IdentifierNode.new('foo'), IdentifierNode.new('bar')
      @parser.stubs(:parse_identifier).returns(a, b)
      @parser.expects(:loop_update_next?).returns(false)
      @parser.expects(:loop_guard_next?).returns(false)
      lambda { @parser.parse_loop_stmt }.must_raise Layo::SyntaxError
    end
  end

  it "should parse loop update" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :nerfin}, {:type => :yr}, {:type => :identifier, :data => 'foo'}
    )
    node = @parser.parse_loop_update
    node.update_op[:type].must_equal :nerfin
    node.must_be_instance_of LoopUpdate
    node.identifier[:data].must_equal 'foo'
  end

  it "should parse loop guard" do
    @tokenizer.stubs(:next_item).returns({:type => :wile})
    expr = ExprNode.new
    @parser.expects(:parse_expr).returns(expr)
    node = @parser.parse_loop_guard
    node.must_be_instance_of LoopGuard
    node.condition_type.must_equal :wile
    node.condition.must_be_same_as expr
  end

  it "should parse func def stmt" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :how_duz_i}, {:type => :identifier, :data => 'hello'},
      {:type => :newline}, {:type => :if_u_say_so}, {:type => :newline}
    )
    func_def_args, block = mock, mock, mock
    @parser.expects(:func_def_args_next?).returns(true)
    @parser.expects(:parse_func_def_args).returns(func_def_args)
    @parser.expects(:parse_block).returns(block)
    node = @parser.parse_func_def_stmt
    node.must_be_instance_of FuncDefStmt
    node.name.must_equal 'hello'
    node.args.must_be_same_as func_def_args
    node.block.must_be_same_as block
  end

  it "should parse func def args" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :yr}, {:type => :identifier, :data => 'arg1'},
      {:type => :an_yr}, {:type => :identifier, :data => 'arg2'},
      {:type => :newline}
    )
    node = @parser.parse_func_def_args
    node.must_be_instance_of FuncDefArgs
    node.args.must_equal ['arg1', 'arg2']
  end

  it "should parse expr stmt" do
    @tokenizer.stubs(:next_item).returns({:type => :newline})
    expr = mock
    @parser.expects(:parse_expr).returns(expr)
    node = @parser.parse_expr_stmt
    node.must_be_instance_of ExprStmt
    node.expr.must_be_same_as expr
  end
end
