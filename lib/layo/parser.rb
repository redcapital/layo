module Layo
  class Parser
    attr_accessor :tokenizer
    attr_reader :functions

    def initialize(tokenizer)
      @tokenizer = tokenizer
      reset
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

    def parse_program
      skip_newlines
      expect_token(:hai)
      version = expect_token(:float)[:data]
      expect_token(:newline)
      block = parse_block
      expect_token(:kthxbye)
      skip_newlines
      expect_token(:eof)
      Ast::Program.new(version, block)
    end

    alias_method :parse, :parse_program

    def expect_token(*types)
      token = @tokenizer.next
      #raise UnexpectedTokenError, token unless types.include?(token[:type])
      unless types.include?(token[:type])
        raise UnexpectedTokenError, token
      end
      token
    end

    def skip_newlines
      while @tokenizer.peek[:type] == :newline
        @tokenizer.next
      end
      @tokenizer.unpeek
    end

    def parse_block
      statements = []
      begin
        skip_newlines
        unless (name = next_statement).nil?
          statements << send("parse_#{name}_statement".to_sym)
        end
      end until name.nil?
      Ast::Block.new(statements)
    end

    def next_statement
      return 'assignment' if @tokenizer.try(:identifier, :r)
      return 'break' if @tokenizer.try(:gtfo)
      return 'cast' if @tokenizer.try(:identifier, :is_now_a)
      return 'condition' if @tokenizer.try(:o_rly?)
      return 'declaration' if @tokenizer.try(:i_has_a)
      return 'function' if @tokenizer.try(:how_duz_i)
      return 'input' if @tokenizer.try(:gimmeh)
      return 'loop' if @tokenizer.try(:im_in_yr)
      return 'print' if @tokenizer.try(:visible)
      return 'return' if @tokenizer.try(:found_yr)
      return 'switch' if @tokenizer.try(:wtf?)
      return 'expression' if !next_expr.nil?
      nil
    end

    def parse_cast_statement
      attrs = { identifier: expect_token(:identifier)[:data] }
      expect_token(:is_now_a)
      attrs[:to] = expect_token(:noob, :troof, :numbr, :numbar, :yarn)[:type]
      expect_token(:newline)
      Ast::Statement.new('cast', attrs)
    end

    def parse_print_statement
      expect_token(:visible)
      attrs = { expressions: [parse_expr] }
      until (name = next_expr).nil?
        attrs[:expressions] << parse_expr(name)
      end
      token = expect_token(:exclamation, :newline)
      attrs[:suppress] = false
      if token[:type] == :exclamation
        expect_token(:newline)
        attrs[:suppress] = true
      end
      Ast::Statement.new('print', attrs)
    end

    # InputStmt ::= TT_GIMMEH IdentifierNode TT_NEWLINE
    def parse_input_statement
      expect_token(:gimmeh)
      attrs = { identifier: expect_token(:identifier)[:data] }
      expect_token(:newline)
      Ast::Statement.new('input', attrs)
    end

    # AssignmentStmt ::= Identifier TT_R Expr TT_NEWLINE
    def parse_assignment_statement
      attrs = { identifier: expect_token(:identifier)[:data] }
      expect_token(:r)
      attrs[:expression] = parse_expr
      expect_token(:newline)
      Ast::Statement.new('assignment', attrs)
    end

    # DeclarationStmt ::= :i_has_a IdentifierNode [:itz ExprNode] TT_NEWLINE
    def parse_declaration_statement
      expect_token(:i_has_a)
      attrs = { identifier: expect_token(:identifier)[:data] }
      if @tokenizer.peek[:type] == :itz
        @tokenizer.next
        attrs[:initialization] = parse_expr
      end
      @tokenizer.unpeek
      expect_token(:newline)
      Ast::Statement.new('declaration', attrs)
    end

    # IfThenElseStmt ::= TT_ORLY TT_NEWLINE TT_YARLY TT_NEWLINE BlockNode ElseIf * [ :no_wai :newline BlockNode ] TT_OIC TT_NEWLINE
    def parse_condition_statement
      expect_token(:o_rly?)
      expect_token(:newline)
      expect_token(:ya_rly)
      expect_token(:newline)
      attrs = { then: parse_block, elseif: [] }
      while @tokenizer.peek[:type] == :mebbe
        expect_token(:mebbe)
        condition = parse_expr
        expect_token(:newline)
        attrs[:elseif] << { condition: condition, block: parse_block }
      end
      @tokenizer.unpeek
      if @tokenizer.peek[:type] == :no_wai
        expect_token(:no_wai)
        expect_token(:newline)
        attrs[:else] = parse_block
      end
      @tokenizer.unpeek
      expect_token(:oic)
      expect_token(:newline)
      Ast::Statement.new('condition', attrs)
    end

    # SwitchStmt ::= TT_WTF TT_NEWLINE Case + [ :omgwtf :newline BlockNode ] TT_OIC TT_NEWLINE
    def parse_switch_statement
      expect_token(:wtf?)
      expect_token(:newline)
      parse_case = lambda do
        expect_token(:omg)
        expression = parse_expr
        expect_token(:newline)
        { expression: expression, block: parse_block }
      end
      attrs = { cases: [parse_case.call] }
      while @tokenizer.peek[:type] == :omg
        attrs[:cases] << parse_case.call
      end
      @tokenizer.unpeek
      if @tokenizer.peek[:type] == :omgwtf
        expect_token(:omgwtf)
        expect_token(:newline)
        attrs[:default] = parse_block
      end
      @tokenizer.unpeek
      expect_token(:oic)
      expect_token(:newline)
      Ast::Statement.new('switch', attrs)
    end

    # BreakStmt ::= TT_GTFO TT_NEWLINE
    def parse_break_statement
      expect_token(:gtfo)
      expect_token(:newline)
      Ast::Statement.new('break')
    end

    # ReturnStmt ::= TT_FOUNDYR ExprNode TT_NEWLINE
    def parse_return_statement
      expect_token(:found_yr)
      attrs = { expression: parse_expr }
      expect_token(:newline)
      Ast::Statement.new('return', attrs)
    end

    # LoopStmt ::= TT_IMINYR IdentifierNode [ LoopUpdate ] [ LoopGuard ] Block TT_NEWLINE TT_IMOUTTAYR IdentifierNode TT_NEWLINE
    def parse_loop_statement
      loop_start = expect_token(:im_in_yr)
      label_begin = expect_token(:identifier)[:data]
      attrs = {}
      if [:uppin, :nerfin, :identifier].include?(@tokenizer.peek[:type])
        attrs[:op] = expect_token(:uppin, :nerfin, :identifier)
        expect_token(:yr)
        attrs[:op] = attrs[:op][:type] == :identifier ? attrs[:op][:data] :
          attrs[:op][:type]
        attrs[:counter] = expect_token(:identifier)[:data]
      end
      @tokenizer.unpeek
      if [:til, :wile].include?(@tokenizer.peek[:type])
        attrs[:guard] = { type: expect_token(:til, :wile)[:type] }
        attrs[:guard][:expression] = parse_expr
      end
      @tokenizer.unpeek
      attrs[:block] = parse_block
      expect_token(:im_outta_yr)
      label_end = expect_token(:identifier)[:data]
      expect_token(:newline)
      unless label_begin == label_end
        raise SyntaxError.new(
          loop_start[:line], loop_start[:pos],
          "Loop labels don't match: '#{label_begin}' and '#{label_end}'"
        )
      end
      attrs[:label] = label_begin
      Ast::Statement.new('loop', attrs)
    end

    # FuncDefStmt ::= TT_HOWDUZ IdentifierNode [ TT_YR IdentifierNode [AN_YR IdentifierNode] * ] TT_NEWLINE BlockNode TT_IFUSAYSO TT_NEWLINE
    def parse_function_statement
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
      Ast::Statement.new('function', { name: name, args: args, block: block })
    end

    # ExprStmt ::= ExprNode TT_NEWLINE
    def parse_expression_statement
      attrs = { expression: parse_expr }
      expect_token(:newline)
      Ast::Statement.new('expression', attrs)
    end

    # Expr ::= CastExpr | ConstantExpr | IdentifierExpr | UnaryOpExpr | BinaryOpExpr | NaryOpExpr
    def parse_expr(name = nil)
      name = next_expr if name.nil?
      raise ParserError, 'Expected expression to parse but not found' if name.nil?
      send("parse_#{name}_expr".to_sym)
    end

    def parse_cast_expr
      expect_token(:maek)
      attrs = { being_casted: parse_expr }
      expect_token(:a)
      attrs[:to] = expect_token(:noob, :troof, :numbr, :numbar, :yarn)[:type]
      Ast::Expression.new('cast', attrs)
    end

    def next_expr
      return 'binary' if @tokenizer.try([
        :sum_of, :diff_of, :produkt_of, :quoshunt_of, :mod_of, :biggr_of,
        :smallr_of, :both_of, :either_of, :won_of, :both_saem, :diffrint
      ])
      return 'cast' if @tokenizer.try(:maek)
      return 'constant' if @tokenizer.try([:boolean, :integer, :float, :string])
      return 'identifier' if @tokenizer.try(:identifier)
      return 'nary' if @tokenizer.try([:all_of, :any_of, :smoosh])
      return 'unary' if @tokenizer.try(:not)
      nil
    end

    # ConstantExpr ::= Boolean | Integer | Float | String
    def parse_constant_expr
      token = expect_token(:boolean, :integer, :float, :string)
      Ast::Expression.new('constant', { vtype: token[:type], value: token[:data] })
    end

    # IdentifierExpr ::= :identifier
    def parse_identifier_expr
      name = expect_token(:identifier)[:data]
      begin
        function = self.functions.fetch(name)
        # Function call
        attrs = { name: name, parameters: [] }
        function.size.times do |c|
          expr_name = next_expr
          if expr_name.nil?
            msg = "Function '%s' expects %d arguments, %d passed" % [name, function.size, c]
            raise ParserError, msg
          end
          attrs[:parameters] << parse_expr(expr_name)
        end
        return Ast::Expression.new('function', attrs)
      rescue KeyError
        # Variable name
        return Ast::Expression.new('variable', name: name)
      end
    end

    # UnaryOpExpr ::= :not Expr
    def parse_unary_expr
      expect_token(:not)
      Ast::Expression.new('unary', { expression: parse_expr } )
    end

    # BinaryOpExpr ::= TT_SUMOF | TT_DIFFOF | TT_PRODUKTOF | TT_QUOSHUNTOF | TT_MODOF | BIGGROF | SMALLROF | TT_BOTHOF | TT_EITHEROF | TT_WONOF ExprNode [:an] ExprNode
    def parse_binary_expr
      attrs = {
        operator: expect_token(
          :sum_of, :diff_of, :produkt_of, :quoshunt_of, :mod_of, :biggr_of,
          :smallr_of, :both_of, :either_of, :won_of, :both_saem, :diffrint
        )[:type]
      }
      attrs[:left] = parse_expr
      @tokenizer.next if @tokenizer.peek[:type] == :an
      @tokenizer.unpeek
      attrs[:right] = parse_expr
      Ast::Expression.new('binary', attrs)
    end

    # NaryOpExpr ::= :all_of | :any_of | :smoosh Expr Expr + :mkay | :newline
    def parse_nary_expr
      attrs = { operator: expect_token(:all_of, :any_of, :smoosh)[:type] }
      attrs[:expressions] = [parse_expr]
      while true
        @tokenizer.next if @tokenizer.peek[:type] == :an
        @tokenizer.unpeek
        name = next_expr
        if name.nil? then break else attrs[:expressions] << parse_expr(name) end
      end
      # Do not consume newline token
      @tokenizer.next if @tokenizer.peek[:type] == :mkay
      @tokenizer.unpeek
      Ast::Expression.new('nary', attrs)
    end
  end
end
