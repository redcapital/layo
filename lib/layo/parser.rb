module Layo
  class Parser
    STATEMENTS = ['cast', 'print', 'input', 'assignment', 'declaration',
      'if_then_else', 'switch', 'break', 'return', 'loop', 'func_def', 'expr']
    EXPRESSIONS = ['cast', 'constant', 'identifier', 'unary_op',
        'binary_op', 'nary_op']
    attr_accessor :tokenizer
    attr_reader :functions

    def initialize(tokenizer)
      @tokenizer = tokenizer
      @functions = {}
    end

    def reset
      @functions = {}
      @tokenizer.reset
    end

    # Function declarations should be parsed first in order to properly
    # parse argument list and allow calling functions before their definition.
    # So this method should be called as the first pass before parsing begins
    def parse_function_declarations
      @tokenizer.reset_peek
      until (token = @tokenizer.peek)[:type] == :eof
        if token[:type] == :how_duz_i
          # Function name must follow
          token = @tokenizer.peek
          unless token[:type] == :identifier
            raise UnexpectedTokenError, token
          end
          name = token[:data]
          args = []
          token = @tokenizer.peek
          if token[:type] == :yr
            # Function arguments must follow
            begin
              token = @tokenizer.peek
              unless token[:type] == :identifier
                raise UnexpectedTokenError, token
              end
              args << token[:data]
            end while @tokenizer.peek[:type] == :an_yr
          end
          @tokenizer.unpeek
          @functions[name] = args
          # Newline must follow
          token = @tokenizer.peek
          unless token[:type] == :newline
            raise UnexpectedTokenError, token
          end
        end
      end
      @tokenizer.reset_peek
    end

    def parse_main
      skip_newlines
      expect_token(:hai)
      version = expect_token(:float)
      expect_token(:newline)
      block = parse_block
      expect_token(:kthxbye)
      skip_newlines
      expect_token(:eof)
      Ast::Main.new(version[:data], block)
    end

    alias_method :parse, :parse_main

    def expect_token(*types)
      token = @tokenizer.next
      raise UnexpectedTokenError, token unless types.include?(token[:type])
      token
    end

    def skip_newlines
      while @tokenizer.peek[:type] == :newline
        @tokenizer.next
      end
      @tokenizer.unpeek
    end

    # Block ::= Stmt *
    def parse_block
      stmts = []
      begin
        skip_newlines
        unless (name = next_stmt_name).nil?
          stmts << send("parse_#{name}_stmt".to_sym)
        end
      end until name.nil?
      Ast::Block.new(stmts)
    end

    def next_stmt_name
      STATEMENTS.each do |name|
        return name if send("#{name}_stmt_next?".to_sym)
      end
      nil
    end

    def cast_stmt_next?
      @tokenizer.try(:identifier, :is_now_a)
    end

    def print_stmt_next?
      @tokenizer.try(:visible)
    end

    def input_stmt_next?
      @tokenizer.try(:gimmeh)
    end

    def assignment_stmt_next?
      @tokenizer.try(:identifier, :r)
    end

    def declaration_stmt_next?
      @tokenizer.try(:i_has_a)
    end

    def if_then_else_stmt_next?
      @tokenizer.try(:o_rly?)
    end

    def switch_stmt_next?
      @tokenizer.try(:wtf?)
    end

    def break_stmt_next?
      @tokenizer.try(:gtfo)
    end

    def return_stmt_next?
      @tokenizer.try(:found_yr)
    end

    def loop_stmt_next?
      @tokenizer.try(:im_in_yr)
    end

    def func_def_stmt_next?
      @tokenizer.try(:how_duz_i)
    end

    def expr_stmt_next?
      !next_expr_name.nil?
    end

    # Type ::= TT_NOOB | TT_TROOF | TT_NUMBR | TT_NUMBAR | TT_YARN
    def parse_type
      token = expect_token(:noob, :troof, :numbr, :numbar, :yarn)
      Ast::Type.new(token[:type])
    end

    # CastStmt ::= IdentifierNode TT_ISNOWA TypeNode TT_NEWLINE
    def parse_cast_stmt
      identifier = expect_token(:identifier)[:data]
      expect_token(:is_now_a)
      type = parse_type
      expect_token(:newline)
      Ast::CastStmt.new(identifier, type)
    end

    # PrintStmt ::= TT_VISIBLE ExprNode + [ TT_BANG ] TT_NEWLINE
    def parse_print_stmt
      expect_token(:visible)
      expr_list = [parse_expr]
      until (name = next_expr_name).nil?
        expr_list << parse_expr(name)
      end
      token = expect_token(:exclamation, :newline)
      suppress = false
      if token[:type] == :exclamation
        expect_token(:newline)
        suppress = true
      end
      Ast::PrintStmt.new(expr_list, suppress)
    end

    # InputStmt ::= TT_GIMMEH IdentifierNode TT_NEWLINE
    def parse_input_stmt
      expect_token(:gimmeh)
      identifier = expect_token(:identifier)[:data]
      expect_token(:newline)
      Ast::InputStmt.new(identifier)
    end

    # AssignmentStmt ::= Identifier TT_R Expr TT_NEWLINE
    def parse_assignment_stmt
      identifier = expect_token(:identifier)[:data]
      expect_token(:r)
      expr = parse_expr
      expect_token(:newline)
      Ast::AssignmentStmt.new(identifier, expr)
    end

    # DeclarationStmt ::= :i_has_a IdentifierNode [:itz ExprNode] TT_NEWLINE
    def parse_declaration_stmt
      expect_token(:i_has_a)
      identifier, initialization = expect_token(:identifier)[:data], nil
      if @tokenizer.peek[:type] == :itz
        @tokenizer.next
        initialization = parse_expr
      end
      @tokenizer.unpeek
      expect_token(:newline)
      Ast::DeclarationStmt.new(identifier, initialization)
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
      @tokenizer.unpeek
      expect_token(:oic)
      expect_token(:newline)
      Ast::IfThenElseStmt.new(block, elseif_list, else_block)
    end

    def elseif_next?
      result = @tokenizer.peek[:type] == :mebbe
      @tokenizer.unpeek
      result
    end

    # ElseIf ::= TT_MEBBE ExprNode TT_NEWLINE BlockNode
    def parse_elseif
      expect_token(:mebbe)
      expr = parse_expr
      expect_token(:newline)
      block = parse_block
      Ast::ElseIf.new(expr, block)
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
      @tokenizer.unpeek
      expect_token(:oic)
      expect_token(:newline)
      Ast::SwitchStmt.new(case_list, default_case)
    end

    def case_next?
      result = @tokenizer.peek[:type] == :omg
      @tokenizer.unpeek
      result
    end

    # Case ::= TT_OMG ExprNode TT_NEWLINE BlockNode
    def parse_case
      expect_token(:omg)
      expr = parse_expr
      expect_token(:newline)
      block = parse_block
      Ast::Case.new(expr, block)
    end

    # BreakStmt ::= TT_GTFO TT_NEWLINE
    def parse_break_stmt
      expect_token(:gtfo)
      expect_token(:newline)
      Ast::BreakStmt.new
    end

    # ReturnStmt ::= TT_FOUNDYR ExprNode TT_NEWLINE
    def parse_return_stmt
      expect_token(:found_yr)
      expr = parse_expr
      expect_token(:newline)
      Ast::ReturnStmt.new(expr)
    end

    # LoopStmt ::= TT_IMINYR IdentifierNode [ LoopUpdate ] [ LoopGuard ] Block TT_NEWLINE TT_IMOUTTAYR IdentifierNode TT_NEWLINE
    def parse_loop_stmt
      loop_start = expect_token(:im_in_yr)
      label_begin = expect_token(:identifier)[:data]
      loop_update = loop_update_next? ? parse_loop_update : nil
      loop_guard = loop_guard_next? ? parse_loop_guard : nil
      block = parse_block
      expect_token(:im_outta_yr)
      label_end = expect_token(:identifier)[:data]
      expect_token(:newline)
      unless label_begin == label_end
        raise SyntaxError.new(
          loop_start[:line], loop_start[:pos],
          "Loop label's don't match: '#{label_begin}' and '#{label_end}'"
        )
      end
      Ast::LoopStmt.new(label_begin, loop_update, loop_guard, block)
    end

    def loop_update_next?
      result = false
      if [:uppin, :nerfin, :identifier].include?(@tokenizer.peek[:type])
        result = @tokenizer.peek[:type] == :yr
        @tokenizer.unpeek
      end
      @tokenizer.unpeek
      result
    end

    # LoopUpdate ::= [:uppin | :nerfin | :identifier] TT_YR IdentifierNode
    def parse_loop_update
      update_op = expect_token(:uppin, :nerfin, :identifier)
      expect_token(:yr)
      Ast::LoopUpdate.new(update_op, expect_token(:identifier))
    end

    def loop_guard_next?
      result = [:til, :wile].include?(@tokenizer.peek[:type])
      @tokenizer.unpeek
      result
    end

    def parse_loop_guard
      token = expect_token(:til, :wile)
      Ast::LoopGuard.new(token[:type], parse_expr)
    end

    # FuncDefStmt ::= TT_HOWDUZ IdentifierNode [ TT_YR IdentifierNode [AN_YR IdentifierNode] * ] TT_NEWLINE BlockNode TT_IFUSAYSO TT_NEWLINE
    def parse_func_def_stmt
      expect_token(:how_duz_i)
      name = expect_token(:identifier)[:data]
      if @functions.has_key?(name)
        # Function definition was parsed in the first pass
        until @tokenizer.next[:type] == :newline; end
        args = @functions[name]
      else
        # Parse argument list as usual
        args = []
        if @tokenizer.peek[:type] == :yr
          begin
            @tokenizer.next
            args << expect_token(:identifier)[:data]
          end while @tokenizer.peek[:type] == :an_yr
        end
        @tokenizer.unpeek
        expect_token(:newline)
        @functions[name] = args
      end
      block = parse_block
      expect_token(:if_u_say_so)
      expect_token(:newline)
      Ast::FuncDefStmt.new(name, args, block)
    end

    # ExprStmt ::= ExprNode TT_NEWLINE
    def parse_expr_stmt
      expr = parse_expr
      expect_token(:newline)
      Ast::ExprStmt.new(expr)
    end

    # Expr ::= CastExpr | ConstantExpr | IdentifierExpr | UnaryOpExpr | BinaryOpExpr | NaryOpExpr
    def parse_expr(name = nil)
      name = next_expr_name if name.nil?
      raise ParserError, 'Expected expression to parse but not found' if name.nil?
      return send("parse_#{name}_expr".to_sym)
    end

    def parse_cast_expr
      expect_token(:maek)
      expr = parse_expr
      expect_token(:a)
      Ast::CastExpr.new(expr, parse_type)
    end

    def next_expr_name(restore_peek = true)
      EXPRESSIONS.each do |name|
        return name if send("#{name}_expr_next?".to_sym)
      end
      nil
    end

    def cast_expr_next?
      @tokenizer.try(:maek)
    end

    def constant_expr_next?
      result = [:boolean, :integer, :float, :string].include?(@tokenizer.peek[:type])
      @tokenizer.unpeek
      result
    end

    def identifier_expr_next?
      @tokenizer.try(:identifier)
    end

    def unary_op_expr_next?
      @tokenizer.try(:not)
    end

    def binary_op_expr_next?
      result = [:sum_of, :diff_of, :produkt_of, :quoshunt_of, :mod_of,
        :biggr_of, :smallr_of, :both_of, :either_of, :won_of, :both_saem,
        :diffrint].include?(@tokenizer.peek[:type])
      @tokenizer.unpeek
      result
    end

    def nary_op_expr_next?
      result = [:all_of, :any_of, :smoosh].include?(@tokenizer.peek[:type])
      @tokenizer.unpeek
      result
    end

    # ConstantExpr ::= Boolean | Integer | Float | String
    def parse_constant_expr
      token = expect_token(:boolean, :integer, :float, :string)
      Ast::ConstantExpr.new(token[:type], token[:data])
    end

    # IdentifierExpr ::= :identifier
    def parse_identifier_expr
      name = expect_token(:identifier)[:data]
      begin
        function = self.functions.fetch(name)
        # Function call
        expr_list = []
        function.size.times do |c|
          expr_name = next_expr_name
          if expr_name.nil?
            msg = 'Function %s expects %d arguments, %d passed' % name, function.size, c
            raise ParserError, msg
          end
          expr_list << parse_expr(expr_name)
        end
        return Ast::FuncCallExpr.new(name, expr_list)
      rescue KeyError
        # Variable name
        return Ast::VariableExpr.new(name)
      end
    end

    # UnaryOpExpr ::= :not Expr
    def parse_unary_op_expr
      expect_token(:not)
      Ast::UnaryOpExpr.new(parse_expr)
    end

    # BinaryOpExpr ::= TT_SUMOF | TT_DIFFOF | TT_PRODUKTOF | TT_QUOSHUNTOF | TT_MODOF | BIGGROF | SMALLROF | TT_BOTHOF | TT_EITHEROF | TT_WONOF ExprNode [:an] ExprNode
    def parse_binary_op_expr
      type = expect_token(
        :sum_of, :diff_of, :produkt_of, :quoshunt_of, :mod_of, :biggr_of,
        :smallr_of, :both_of, :either_of, :won_of, :both_saem, :diffrint
      )[:type]
      expr1 = parse_expr
      token = @tokenizer.peek
      @tokenizer.next if token[:type] == :an
      @tokenizer.unpeek
      Ast::BinaryOpExpr.new(type, expr1, parse_expr)
    end

    # NaryOpExpr ::= :all_of | :any_of | :smoosh Expr Expr + :mkay | :newline
    def parse_nary_op_expr
      type = expect_token(:all_of, :any_of, :smoosh)[:type]
      expr_list = [parse_expr]
      while true
        @tokenizer.next if @tokenizer.peek[:type] == :an
        @tokenizer.unpeek
        name = next_expr_name
        if name.nil? then break else expr_list << parse_expr(name) end
      end
      # Do not consume newline token
      if @tokenizer.peek[:type] == :mkay then @tokenizer.next else @tokenizer.unpeek end
      Ast::NaryOpExpr.new(type, expr_list)
    end
  end
end
