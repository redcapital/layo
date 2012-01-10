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

  it "should restore peek index after statement lookaheads" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :identifier, :data => 'abc'},
      {:type => :is_now_a}, {:type => :newline}
    )
    @parser.next_statement.must_equal 'cast'
    @tokenizer.peek.must_equal :type => :identifier, :data => 'abc'
  end

  it "should restore peek index after expression lookaheads" do
    @tokenizer.stubs(:next_item).returns({:type => :string, :data => 'abc'})
    @parser.next_expression.must_equal 'constant'
    @tokenizer.peek.must_equal :type => :string, :data => 'abc'
  end

  it 'should parse program' do
    @tokenizer.stubs(:next_item).returns(
      {:type => :hai}, {:type => :float, :data => 1.2},
      {:type => :newline}, {:type => :kthxbye}, {:type => :eof}
    )
    block = mock
    @parser.expects(:parse_block).returns(block)
    node = @parser.parse_program
    node.must_be_instance_of Program
    node.version.must_equal 1.2
    node.block.must_be_same_as block
  end

  it "should parse block" do
    statements = [mock]
    @parser.stubs(:skip_newlines)
    @parser.stubs(:parse_statement).returns(*statements)
    @parser.stubs(:next_statement).returns('print', nil)
    node = @parser.parse_block
    node.must_be_instance_of Block
    node.statement_list.must_equal statements
  end

  it "should parse cast statement" do
    @tokenizer.stubs(:next_item).returns(
      { type: :identifier, data: 'abc' },
      { type: :is_now_a}, { type: :troof }
    )
    node = @parser.parse_cast_statement
    node.type.must_equal 'cast'
    node.identifier.must_equal 'abc'
    node.to.must_equal :troof
  end

  describe "#parse_print_statement" do
    it "should parse print statement with exclamation mark" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :visible}, {:type => :exclamation}
      )
      expr = mock
      @parser.expects(:parse_expression).returns(expr)
      @parser.stubs(:next_expression).returns(nil)
      node = @parser.parse_print_statement
      node.type.must_equal 'print'
      node.expressions.size.must_equal 1
      node.expressions.first.must_be_same_as expr
      node.suppress.must_equal true
    end

    it "should parse print statement without exclamation mark" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :visible}
      )
      exprs = [mock, mock]
      @parser.stubs(:parse_expression).returns(*exprs)
      @parser.stubs(:next_expression).returns('constant', nil)
      node = @parser.parse_print_statement
      node.type.must_equal 'print'
      node.expressions.must_equal exprs
      node.suppress.must_equal false
    end
  end

  it "should parse input statement" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :gimmeh}, {:type => :identifier, :data => 'var'},
    )
    node = @parser.parse_input_statement
    node.type.must_equal 'input'
    node.identifier.must_equal 'var'
  end

  it "should parse assignment statement" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :identifier, :data => 'abc'}, {:type => :r}
    )
    expr = mock
    @parser.expects(:parse_expression).returns(expr)
    node = @parser.parse_assignment_statement
    node.type.must_equal 'assignment'
    node.identifier.must_equal 'abc'
    node.expression.must_be_same_as expr
  end

  describe "#parse_declaration_statement" do
    it "should parse declaration statement without initialization" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :i_has_a}, {:type => :identifier, :data => 'abc'}
      )
      node = @parser.parse_declaration_statement
      node.type.must_equal 'declaration'
      node.identifier.must_equal 'abc'
      node.initialization.must_be_nil
    end

    it "should parse declaration statement with initialization" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :i_has_a}, {:type => :identifier, :data => 'abc'},
        {:type => :itz}
      )
      init = mock
      @parser.expects(:parse_expression).returns(init)
      node = @parser.parse_declaration_statement
      node.type.must_equal 'declaration'
      node.identifier.must_equal 'abc'
      node.initialization.must_be_same_as init
    end
  end

  describe "#parse_condition_statement" do
    before do
      @tokenizer_expectation = @tokenizer.stubs(:next_item).returns(
        {:type => :o_rly?}, {:type => :newline},
        {:type => :ya_rly}, {:type => :newline}
      )
      @block = mock
      @parser_expectation = @parser.stubs(:parse_block).returns(@block)
    end

    it "should parse conditional statement without else's" do
      @tokenizer_expectation.then.returns({:type => :oic})
      node = @parser.parse_condition_statement
      node.type.must_equal 'condition'
      node.then.must_be_same_as @block
      node.elseif.must_be_empty
    end

    it "should parse conditional statement with else and elseif's" do
      @tokenizer_expectation.then.returns(
        { type: :mebbe }, { type: :newline },
        {:type => :no_wai}, {:type => :newline},
        {:type => :oic}
      )
      elseif_condition = mock
      elseif_block = mock
      else_block = mock
      @parser.stubs(:parse_expression).returns(elseif_condition)
      @parser_expectation.then.returns(elseif_block, else_block)

      node = @parser.parse_condition_statement

      node.type.must_equal 'condition'
      node.then.must_be_same_as @block
      node.elseif.first[:condition].must_be_same_as elseif_condition
      node.elseif.first[:block].must_be_same_as elseif_block
      node.else.must_be_same_as else_block
    end
  end

  it "should parse switch statement" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :wtf?}, {:type => :newline},
      # One case
      { type: :omg }, { type: :newline },
      # Default case
      {:type => :omgwtf}, {:type => :newline},
      {:type => :oic}
    )
    kase_expr, kase, default = mock, mock, mock
    @parser.expects(:parse_expression).returns(kase_expr)
    @parser.stubs(:parse_block).returns(kase, default)

    node = @parser.parse_switch_statement

    node.type.must_equal 'switch'
    node.cases.first[:expression].must_be_same_as kase_expr
    node.cases.first[:block].must_be_same_as kase
    node.default.must_be_same_as default
  end

  it "should parse break statement" do
    @tokenizer.stubs(:next_item).returns({:type => :gtfo})
    node = @parser.parse_break_statement
    node.type.must_equal 'break'
  end

  it "should parse return statement" do
    @tokenizer.stubs(:next_item).returns({:type => :found_yr})
    expr = mock
    @parser.expects(:parse_expression).returns(expr)
    node = @parser.parse_return_statement
    node.type.must_equal 'return'
    node.expression.must_be_same_as expr
  end

  describe "#parse_loop_statement" do
    it "should parse loop statement" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :im_in_yr}, {:type => :identifier, :data => 'abc'},
        # Loop operation
        { type: :uppin }, { type: :yr }, { type: :identifier, data: 'i' },
        # Loop condition
        { type: :wile },
        {:type => :im_outta_yr}, {:type => :identifier, :data => 'abc'}
      )
      expr, block = mock, mock
      @parser.expects(:parse_expression).returns(expr)
      @parser.expects(:parse_block).returns(block)

      node = @parser.parse_loop_statement

      node.type.must_equal 'loop'
      node.label.must_equal 'abc'
      node.op.must_equal :uppin
      node.counter.must_equal 'i'
      node.guard[:type].must_equal :wile
      node.guard[:expression].must_be_same_as expr
      node.block.must_be_same_as block
    end

    it "should raise exception if labels are not equal" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :im_in_yr, :line => 1, :pos => 1},
        {:type => :identifier, :data => 'foo'},
        {:type => :newline}, {:type => :im_outta_yr},
        {:type => :identifier, :data => 'bar'}
      )
      lambda { @parser.parse_loop_statement }.must_raise Layo::SyntaxError
    end
  end

  it "should parse function statement" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :how_duz_i}, {:type => :identifier, :data => 'hello'},
      {:type => :newline}, {:type => :if_u_say_so}
    )
    block = mock
    @parser.expects(:parse_block).returns(block)
    node = @parser.parse_function_statement
    node.type.must_equal 'function'
    node.name.must_equal 'hello'
    node.block.must_be_same_as block
    node.args.must_equal []
  end

  it "should parse expression statement" do
    expr = mock
    @parser.expects(:parse_expression).returns(expr)
    node = @parser.parse_expression_statement
    node.type.must_equal 'expression'
    node.expression.must_be_same_as expr
  end

  it "should parse cast expression" do
    @tokenizer.stubs(:next_item).returns(
      {:type => :maek}, {:type => :a}, {:type => :troof}
    )
    expr = mock
    @parser.expects(:parse_expression).returns(expr)
    node = @parser.parse_cast_expression
    node.type.must_equal 'cast'
    node.being_casted.must_be_same_as expr
    node.to.must_equal :troof
  end

  describe "#parse_constant_expressionession" do
    it "should parse boolean values" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :boolean, :data => true},
        {:type => :boolean, :data => false}
      )
      node = @parser.parse_constant_expression
      node.type.must_equal 'constant'
      node.vtype.must_equal :boolean
      node.value.must_equal true

      node = @parser.parse_constant_expression
      node.value.must_equal false
    end

    it "should parse integer values" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :integer, :data => 567}
      )
      node = @parser.parse_constant_expression
      node.value.must_equal 567
    end

    it "should parse float values" do
      @tokenizer.stubs(:next_item).returns(
        {:type => :float, :data => -5.234}
      )
      node = @parser.parse_constant_expression
      node.value.must_equal -5.234
    end

    it "should parse string values" do
      @tokenizer.stubs(:next_item).returns :type => :string, :data => 'some value'
      node = @parser.parse_constant_expression
      node.value.must_equal 'some value'
    end
  end

  describe '#parse_identifier_expression' do
    it "should parse variable expression" do
      @tokenizer.stubs(:next_item).returns({:type => :identifier, :data => 'var'})
      node = @parser.parse_identifier_expression
      node.type.must_equal 'variable'
      node.name.must_equal 'var'
    end

    it "should parse function expression" do
      @tokenizer.stubs(:next_item).returns({:type => :identifier, :data => 'foo'})
      exprs = [mock, mock]
      @parser.stubs(:functions).returns({'foo' => ['arg1', 'arg2']})
      @parser.stubs(:next_expression).returns('cast', 'constant')
      @parser.stubs(:parse_expression).returns(*exprs)
      node = @parser.parse_identifier_expression
      node.type.must_equal 'function'
      node.name.must_equal 'foo'
      node.parameters.must_equal exprs
    end
  end

  it "should parse unary expr" do
    @tokenizer.stubs(:next_item).returns({:type => :not})
    expr = mock
    @parser.expects(:parse_expression).returns(expr)
    node = @parser.parse_unary_expression
    node.type.must_equal 'unary'
    node.expression.must_be_same_as expr
  end

  it "should parse binary expr" do
    @tokenizer.stubs(:next_item).returns({:type => :both_of})
    expr1, expr2 = mock, mock
    @parser.stubs(:parse_expression).returns(expr1, expr2)
    node = @parser.parse_binary_expression
    node.type.must_equal 'binary'
    node.operator.must_equal :both_of
    node.left.must_be_same_as expr1
    node.right.must_be_same_as expr2
  end

  it "should parse nary expr" do
    @tokenizer.stubs(:next_item).returns({:type => :any_of}, {:type => :mkay})
    expressions = [mock, mock, mock]
    @parser.stubs(:parse_expression).returns(*expressions)
    @parser.stubs(:next_expression).returns('constant', 'constant', nil)
    node = @parser.parse_nary_expression
    node.type.must_equal 'nary'
    node.operator.must_equal :any_of
    node.expressions.must_equal expressions
  end
end
