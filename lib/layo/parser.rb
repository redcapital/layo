module Layo
  class Parser
    attr_accessor :tokenizer

    def initialize(tokenizer)
      @tokenizer = tokenizer
    end

    def parse
      expect_token(:hai)
      version = expect_token(:float)
      expect_token(:newline)
      block = parse_block
      expect_token(:eof)
      Ast::Main.new(version[:data], block)
    end

    def expect_token(*types)
      token = @tokenizer.next
      raise UnexpectedTokenError, token unless types.include?(token[:type])
      token
    end

    # Block ::= Stmt *
    def parse_block
      stmts = []
      while stmt_next?
        stmts << parse_stmt
      end
      Block.new(stmts)
    end

    # StmtNode ::= CastStmtNode | PrintStmtNode | InputStmtNode | AssignmentStmtNode | DeclarationStmtNode | IfThenElseStmtNode | SwitchStmtNode | BreakStmt | ReturnStmtNode | LoopStmtNode | FuncDefStmtNode | ExprStmt
    def parse_stmt
      ['cast', 'print', 'input', 'assignment', 'declaration', 'if_then_else', 
        'switch', 'break', 'return', 'loop', 'func_def', 'expr'].each do |name|
        ok = send("#{name}_stmt_next?".to_sym) 
        @tokenizer.reset_peek
        return send("parse_#{name}_stmt".to_sym) if ok
      end
      raise ParserError, 'Expected statement to parse but not found'
    end

    def stmt_next?
      cast_stmt_next? or print_stmt_next? or input_stmt_next? or
      assignment_stmt_next? or declaration_stmt_next? or
      if_then_else_stmt_next? or switch_stmt_next? or
      break_stmt_next? or return_stmt_next? or
      loop_stmt_next? or func_def_stmt_next? or expr_stmt_next?
    end

    def cast_stmt_next?
      @tokenizer.peek[:type] == :identifier && @tokenizer.peek[:type] == :is_now_a
    end

    def print_stmt_next?
      @tokenizer.peek[:type] == :visible
    end

    def input_stmt_next?
      @tokenizer.peek[:type] == :gimmeh
    end

    def assignment_stmt_next?
      @tokenizer.peek[:type] == :identifier && @tokenizer.peek[:type] == :r
    end

    def declaration_stmt_next?
      @tokenizer.peek[:type] == :identifier && @tokenizer.peek[:type] == :i_has_a
    end

    def if_then_else_stmt_next?
      @tokenizer.peek[:type] == :o_rly?
    end

    def switch_stmt_next?
      @tokenizer.peek[:type] == :wtf?
    end

    def break_stmt_next?
      @tokenizer.peek[:type] == :gtfo
    end

    def return_stmt_next?
      @tokenizer.peek[:type] == :found_yr
    end

    def loop_stmt_next?
      @tokenizer.peek[:type] == :im_in_yr
    end

    def func_def_stmt_next?
      @tokenizer.peek[:type] == :how_duz_i
    end

    def expr_stmt_next?
      expr_next? && @tokenizer.peek[:type] == :newline
    end

    # Type ::= TT_NOOB | TT_TROOF | TT_NUMBR | TT_NUMBAR | TT_YARN
    def parse_type
      token = expect_token(:noob, :troof, :numbr, :numbar, :yarn)
      Type.new(token[:type])
    end

    # CastStmt ::= IdentifierNode TT_ISNOWA TypeNode TT_NEWLINE
    def parse_cast_stmt
      identifier = expect_token(:identifier)[:data]
      expect_token(:is_now_a)
      type = parse_type
      expect_token(:newline)
      CastStmt.new(identifier, type)
    end

    # PrintStmt ::= TT_VISIBLE ExprNode + [ TT_BANG ] TT_NEWLINE
    def parse_print_stmt
      expect_token(:visible)
      expr_list = [parse_expr]
      while expr_next?
        expr_list << parse_expr
      end
      token = expect_token(:exclamation, :newline)
      suppress = false
      if token[:type] == :exclamation
        expect_token(:newline)
        suppress = true
      end
      PrintStmt.new(expr_list, suppress)
    end

    # InputStmt ::= TT_GIMMEH IdentifierNode TT_NEWLINE
    def parse_input_stmt
      expect_token(:gimmeh)
      identifier = expect_token(:identifier)[:data]
      expect_token(:newline)
      InputStmt.new(identifier)
    end

    # AssignmentStmt ::= Identifier TT_R Expr TT_NEWLINE
    def parse_assignment_stmt
      identifier = expect_token(:identifier)[:data]
      expect_token(:r)
      expr = parse_expr
      expect_token(:newline)
      AssignmentStmt.new(identifier, expr)
    end

    # DeclarationStmt ::= :i_has_a IdentifierNode [:itz ExprNode] TT_NEWLINE
    def parse_declaration_stmt
      expect_token(:i_has_a)
      identifier, initialization = expect_token(:identifier)[:data], nil
      if @tokenizer.peek[:type] == :itz
        @tokenizer.next
        initialization = parse_expr
      end
      expect_token(:newline)
      DeclarationStmt.new(identifier, initialization)
    end

    # IfThenElseStmt ::= TT_ORLY TT_NEWLINE TT_YARLY TT_NEWLINE BlockNode ElseIf * [ :no_wai :newline BlockNode ] TT_OIC TT_NEWLINE
    def parse_if_then_else_stmt
      expect_token(:o_rly?)
      expect_token(:newline)
      expect_token(:ya_rly)
      expect_token(:newline)
      block = parse_block
      elseif_list = []
      while elseif_next?
        elseif_list << parse_elseif
      end
      else_block = nil
      if @tokenizer.peek[:type] == :no_wai
        @tokenizer.next
        expect_token(:newline)
        else_block = parse_block
      end
      expect_token(:oic)
      expect_token(:newline)
      IfThenElseStmt.new(block, elseif_list, else_block)
    end

    def elseif_next?
      @tokenizer.peek[:type] == :mebbe
    end

    # ElseIf ::= TT_MEBBE ExprNode TT_NEWLINE BlockNode
    def parse_elseif
      expect_token(:mebbe)
      expr = parse_expr
      expect_token(:newline)
      block = parse_block
      ElseIf.new(expr, block)
    end

    # SwitchStmt ::= TT_WTF TT_NEWLINE Case + [ :omgwtf :newline BlockNode ] TT_OIC TT_NEWLINE
    def parse_switch_stmt
      expect_token(:wtf?)
      expect_token(:newline)
      case_list = [parse_case]
      while case_next?
        case_list << parse_case
      end
      default_case = nil
      if @tokenizer.peek[:type] == :omgwtf
        @tokenizer.next
        expect_token(:newline)
        default_case = parse_block
      end
      expect_token(:oic)
      expect_token(:newline)
      SwitchStmt.new(case_list, default_case)
    end

    def case_next?
      @tokenizer.peek[:type] == :omg
    end

    # Case ::= TT_OMG ExprNode TT_NEWLINE BlockNode
    def parse_case
      expect_token(:omg)
      expr = parse_expr
      expect_token(:newline)
      block = parse_block
      Case.new(expr, block)
    end

    # BreakStmt ::= TT_GTFO TT_NEWLINE
    def parse_break_stmt
      expect_token(:gtfo)
      expect_token(:newline)
      BreakStmt.new
    end

    # ReturnStmt ::= TT_FOUNDYR ExprNode TT_NEWLINE
    def parse_return_stmt
      expect_token(:found_yr)
      expr = parse_expr
      expect_token(:newline)
      ReturnStmt.new(expr)
    end

    # LoopStmt ::= TT_IMINYR IdentifierNode [ LoopUpdate ] [ LoopGuard ] TT_NEWLINE TT_IMOUTTAYR IdentifierNode TT_NEWLINE
    def parse_loop_stmt
      loop_start = expect_token(:im_in_yr)
      label_begin = expect_token(:identifier)[:data]
      loop_update = loop_update_next? ? parse_loop_update : nil
      loop_guard = loop_guard_next? ? parse_loop_guard : nil
      expect_token(:newline)
      expect_token(:im_outta_yr)
      label_end = expect_token(:identifier)[:data]
      expect_token(:newline)
      unless label_begin == label_end
        raise SyntaxError.new(
          loop_start[:line], loop_start[:pos],
          "Loop label's don't match: '#{label_begin}' and '#{label_end}'"
        )
      end
      LoopStmt.new(label_begin, loop_update, loop_guard)
    end

    def loop_update_next?
      [:uppin, :nerfin, :identifier].include?(@tokenizer.peek[:type]) &&
        @tokenizer.peek[:type] == :yr
    end

    # LoopUpdate ::= [:uppin | :nerfin | :identifier] TT_YR IdentifierNode
    def parse_loop_update
      update_op = expect_token(:uppin, :nerfin, :identifier)
      expect_token(:yr)
      LoopUpdate.new(update_op, expect_token(:identifier))
    end

    def loop_guard_next?
      [:til, :wile].include?(@tokenizer.peek[:type])
    end

    def parse_loop_guard
      token = expect_token(:til, :wile)
      LoopGuard.new(token[:type], parse_expr)
    end

    # FuncDefStmt ::= TT_HOWDUZ IdentifierNode [ FunctionDefArgs ] TT_NEWLINE BlockNode TT_IFUSAYSO TT_NEWLINE
    def parse_func_def_stmt
      expect_token(:how_duz_i)
      name = expect_token(:identifier)[:data]
      args = func_def_args_next? ? parse_func_def_args : nil
      expect_token(:newline)
      block = parse_block
      expect_token(:if_u_say_so)
      expect_token(:newline)
      FuncDefStmt.new(name, args, block)
    end

    def func_def_args_next?
      @tokenizer.peek[:type] == :yr
    end

    # FuncDefArgs ::= TT_YR IdentifierNode [:an_yr :identifier]*
    def parse_func_def_args
      expect_token(:yr)
      args = [expect_token(:identifier)[:data]]
      while @tokenizer.peek[:type] == :an_yr
        @tokenizer.next
        args << expect_token(:identifier)[:data]
      end
      @tokenizer.reset_peek
      FuncDefArgs.new(args)
    end

    # ExprStmt ::= ExprNode TT_NEWLINE
    def parse_expr_stmt
      expr = parse_expr
      expect_token(:newline)
      ExprStmt.new(expr)
    end

    # Expr ::= CastExpr | ConstantExpr | VariableExpr | FuncCallExpr | UnaryOpExpr | BinaryOpExpr | NaryOpExpr
    def parse_expr
      ['cast', 'constant', 'variable', 'func_call', 'unary_op', 
        'binary_op', 'nary_op'].each do |name|
        ok = send("#{name}_expr_next?".to_sym) 
        @tokenizer.reset_peek
        return send("parse_#{name}_expr".to_sym) if ok
      end
      raise ParserError, 'Expected expression to parse but not found'
    end

    def parse_cast_expr
      expect_token(:maek)
      expr = parse_expr
      expect_token(:a)
      CastExpr.new(expr, parse_type)
    end

    def expr_next?
      cast_expr_next? or constant_expr_next? or variable_expr_next?
      func_call_expr_next? or unary_op_expr_next? or binary_op_expr_next? or
      nary_op_expr_next?
    end

    def cast_expr_next?
      @tokenizer.peek[:type] == :maek
    end

    def constant_expr_next?
      [:boolean, :integer, :float, :string].include?(@tokenizer.peek[:type])
    end

    def variable_expr_next?
      @tokenizer.peek[:type] == :identifier
    end

    def func_call_expr_next?
      @tokenizer.peek[:type] == :identifier && expr_next?
    end

    def unary_op_expr_next?
      @tokenizer.peek[:type] == :not
    end

    def binary_op_expr_next?
      [:sum_of, :diff_of, :produkt_of, :quoshunt_of, :mod_of, :biggr_of, 
        :smallr_of, :both_of, :either_of, :won_of].include?(@tokenizer.peek[:type])
    end

    def nary_op_expr_next?
      [:all_of, :any_of, :smoosh].include?(@tokenizer.peek[:type])
    end

    # ConstantExpr ::= Boolean | Integer | Float | String
    def parse_constant_expr
      token = expect_token(:boolean, :integer, :float, :string)
      ConstantExpr.new(token[:type], token[:data])
    end

    # VariableExpr ::= :identifier
    def parse_variable_expr
      name = expect_token(:identifier)[:data]
      VariableExpr.new(name)
    end

    # FuncCallExpr ::= :identifier ExprNode *
    def parse_func_call_expr
      name = expect_token(:identifier)[:data]
      expr_list = []
      while expr_next?
        expr_list << parse_expr
      end
      FuncCallExpr.new(name, expr_list)
    end

    # UnaryOpExpr ::= :not Expr
    def parse_unary_op_expr
      expect_token(:not)
      UnaryOpExpr.new(parse_expr)
    end

    # BinaryOpExpr ::= TT_SUMOF | TT_DIFFOF | TT_PRODUKTOF | TT_QUOSHUNTOF | TT_MODOF | BIGGROF | SMALLROF | TT_BOTHOF | TT_EITHEROF | TT_WONOF ExprNode [:an] ExprNode
    def parse_binary_op_expr
      type = expect_token(
        :sum_of, :diff_of, :produkt_of, :quoshunt_of, :mod_of, 
        :biggr_of, :smallr_of, :both_of, :either_of, :won_of
      )[:type]
      expr1 = parse_expr
      token = @tokenizer.peek
      @tokenizer.next if token[:type] == :an
      @tokenizer.reset_peek
      BinaryOpExpr.new(type, expr1, parse_expr)
    end

    # NaryOpExpr ::= :all_of | :any_of | :smoosh Expr Expr + :mkay | :newline
    def parse_nary_op_expr
      type = expect_token(:all_of, :any_of, :smoosh)[:type]
      expr_list = [parse_expr]
      begin
        expr_list << parse_expr
      end while expr_next?
      token = @tokenizer.peek
      # Do not consume newline token
      @tokenizer.next if token[:type] == :mkay
      @tokenizer.reset_peek
      NaryOpExpr.new(type, expr_list)
    end
  end
end
