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
      block_node = parse_block
      expect_token(:eof)
      Ast::MainNode.new(version[:data], block_node)
    end

    def expect_token(*types)
      token = @tokenizer.next
      raise UnexpectedTokenError, token unless types.include?(token[:type])
      token
    end

    # BlockNode ::= StmtNode *
    def parse_block
      stmts = []
      while stmt_next?
        stmts << parse_stmt
      end
      BlockNode.new(stmts)
    end

    # ConstantNode ::= Boolean | Integer | Float | String
    def parse_constant
      token = expect_token(:boolean, :integer, :float, :string)
      ConstantNode.new(token[:type], token[:data])
    end

    # IdentifierNode ::= :identifier
    def parse_identifier
      token = expect_token(:identifier)
      IdentifierNode.new(token[:data])
    end

    # TypeNode ::= TT_NOOB | TT_TROOF | TT_NUMBR | TT_NUMBAR | TT_YARN
    def parse_type
      token = expect_token(:noob, :troof, :numbr, :numbar, :yarn)
      TypeNode.new(token[:type])
    end

    # CastStmtNode ::= IdentifierNode TT_ISNOWA TypeNode TT_NEWLINE
    def parse_cast_stmt
      identifier = parse_identifier
      expect_token(:is_now_a)
      type = parse_type
      expect_token(:newline)
      CastStmtNode.new(identifier, type)
    end

    # PrintStmtNode ::= TT_VISIBLE ExprNode + [ TT_BANG ] TT_NEWLINE
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
      PrintStmtNode.new(expr_list, suppress)
    end

    # InputStmtNode ::= TT_GIMMEH IdentifierNode TT_NEWLINE
    def parse_input_stmt
      expect_token(:gimmeh)
      identifier = parse_identifier
      expect_token(:newline)
      InputStmtNode.new(identifier)
    end

    # AssignmentStmtNode ::= IdentifierNode TT_R ExprNode TT_NEWLINE
    def parse_assignment_stmt
      identifier = parse_identifier
      expect_token(:r)
      expr = parse_expr
      expect_token(:newline)
      AssignmentStmtNode.new(identifier, expr)
    end

    # DeclarationStmtNode ::= :i_has_a IdentifierNode [:itz ExprNode] TT_NEWLINE
    def parse_declaration_stmt
      expect_token(:i_has_a)
      identifier, initialization = parse_identifier, nil
      if @tokenizer.peek[:type] == :itz
        @tokenizer.next
        initialization = parse_expr
      end
      expect_token(:newline)
      DeclarationStmtNode.new(identifier, initialization)
    end

    # IfThenElseStmtNode ::= TT_ORLY TT_NEWLINE TT_YARLY TT_NEWLINE BlockNode ElseIf * [ :no_wai :newline BlockNode ] TT_OIC TT_NEWLINE
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
      IfThenElseStmtNode.new(block, elseif_list, else_block)
    end

    # ElseIf ::= TT_MEBBE ExprNode TT_NEWLINE BlockNode
    def parse_elseif
      expect_token(:mebbe)
      expr = parse_expr
      expect_token(:newline)
      block = parse_block
      ElseIf.new(expr, block)
    end

    # SwitchStmtNode ::= TT_WTF TT_NEWLINE Case + [ :omgwtf :newline BlockNode ] TT_OIC TT_NEWLINE
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
      SwitchStmtNode.new(case_list, default_case)
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
      BreakStmtNode.new
    end

    # ReturnStmtNode ::= TT_FOUNDYR ExprNode TT_NEWLINE
    def parse_return_stmt
      expect_token(:found_yr)
      expr = parse_expr
      expect_token(:newline)
      ReturnStmtNode.new(expr)
    end

    # LoopStmtNode ::= TT_IMINYR IdentifierNode [ LoopUpdate ] [ LoopGuard ] TT_NEWLINE TT_IMOUTTAYR IdentifierNode TT_NEWLINE
    def parse_loop_stmt
      loop_start = expect_token(:im_in_yr)
      label_begin = parse_identifier
      loop_update = loop_update_next? ? parse_loop_update : nil
      loop_guard = loop_guard_next? ? parse_loop_guard : nil
      expect_token(:newline)
      expect_token(:im_outta_yr)
      label_end = parse_identifier
      expect_token(:newline)
      unless label_begin.data == label_end.data
        raise SyntaxError.new(
          loop_start[:line], loop_start[:pos],
          "Loop label's don't match: '#{label_begin.data}' and '#{label_end.data}'"
        )
      end
      LoopStmtNode.new(label_begin, loop_update, loop_guard)
    end

    # LoopUpdate ::= [:uppin | :nerfin | :identifier] TT_YR IdentifierNode
    def parse_loop_update
      update_op = expect_token(:uppin, :nerfin, :identifier)
      expect_token(:yr)
      LoopUpdate.new(update_op, expect_token(:identifier))
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

    # FuncDefArgs ::= TT_YR IdentifierNode [:an_yr :identifier]*
    def parse_func_def_args
      expect_token(:yr)
      args = [expect_token(:identifier)[:data]]
      while @tokenizer.peek[:type] == :an_yr
        @tokenizer.next
        args << expect_token(:identifier)[:data]
      end
      FuncDefArgs.new(args)
    end

    def parse_expr_stmt
      expr = parse_expr
      expect_token(:newline)
      ExprStmt.new(expr)
    end
  end
end
