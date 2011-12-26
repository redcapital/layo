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
      raise UnexpectedTokenError, token unless types.include?(token[:type])
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
          statements << parse_statement(name)
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
      return 'expression' if !next_expression.nil?
      nil
    end

    def parse_statement(name)
      statement = send("parse_#{name}_statement".to_sym)
      expect_token(:newline)
      statement
    end

    def parse_assignment_statement
      attrs = { identifier: expect_token(:identifier)[:data] }
      expect_token(:r)
      attrs[:expression] = parse_expression
      Ast::Statement.new('assignment', attrs)
    end

    def parse_break_statement
      expect_token(:gtfo)
      Ast::Statement.new('break')
    end

    def parse_cast_statement
      attrs = { identifier: expect_token(:identifier)[:data] }
      expect_token(:is_now_a)
      attrs[:to] = expect_token(:noob, :troof, :numbr, :numbar, :yarn)[:type]
      Ast::Statement.new('cast', attrs)
    end

    def parse_condition_statement
      expect_token(:o_rly?)
      expect_token(:newline)
      expect_token(:ya_rly)
      expect_token(:newline)
      attrs = { then: parse_block, elseif: [] }
      while @tokenizer.peek[:type] == :mebbe
        expect_token(:mebbe)
        condition = parse_expression
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
      Ast::Statement.new('condition', attrs)
    end

    def parse_declaration_statement
      expect_token(:i_has_a)
      attrs = { identifier: expect_token(:identifier)[:data] }
      if @tokenizer.peek[:type] == :itz
        @tokenizer.next
        attrs[:initialization] = parse_expression
      end
      @tokenizer.unpeek
      Ast::Statement.new('declaration', attrs)
    end

    def parse_expression_statement
      attrs = { expression: parse_expression }
      Ast::Statement.new('expression', attrs)
    end

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
      Ast::Statement.new('function', { name: name, args: args, block: block })
    end

    def parse_input_statement
      expect_token(:gimmeh)
      attrs = { identifier: expect_token(:identifier)[:data] }
      Ast::Statement.new('input', attrs)
    end

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
        attrs[:guard][:expression] = parse_expression
      end
      @tokenizer.unpeek
      attrs[:block] = parse_block
      expect_token(:im_outta_yr)
      label_end = expect_token(:identifier)[:data]
      unless label_begin == label_end
        raise SyntaxError.new(
          loop_start[:line], loop_start[:pos],
          "Loop labels don't match: '#{label_begin}' and '#{label_end}'"
        )
      end
      attrs[:label] = label_begin
      Ast::Statement.new('loop', attrs)
    end

    def parse_print_statement
      expect_token(:visible)
      attrs = { expressions: [parse_expression] }
      until (name = next_expression).nil?
        attrs[:expressions] << parse_expression(name)
      end
      attrs[:suppress] = false
      if @tokenizer.peek[:type] == :exclamation
        @tokenizer.next
        attrs[:suppress] = true
      end
      @tokenizer.unpeek
      Ast::Statement.new('print', attrs)
    end

    def parse_return_statement
      expect_token(:found_yr)
      attrs = { expression: parse_expression }
      Ast::Statement.new('return', attrs)
    end

    def parse_switch_statement
      expect_token(:wtf?)
      expect_token(:newline)
      parse_case = lambda do
        expect_token(:omg)
        expression = parse_expression
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
      Ast::Statement.new('switch', attrs)
    end

    # Returns internal name of the next expression
    # Modifies peek index of the tokenizer if result is non-nil
    def next_expression
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

    def parse_expression(name = nil)
      name = next_expression if name.nil?
      raise ParserError, 'Expected expression to parse but not found' if name.nil?
      send("parse_#{name}_expression".to_sym)
    end

    def parse_binary_expression
      attrs = {
        operator: expect_token(
          :sum_of, :diff_of, :produkt_of, :quoshunt_of, :mod_of, :biggr_of,
          :smallr_of, :both_of, :either_of, :won_of, :both_saem, :diffrint
        )[:type]
      }
      attrs[:left] = parse_expression
      @tokenizer.next if @tokenizer.peek[:type] == :an
      @tokenizer.unpeek
      attrs[:right] = parse_expression
      Ast::Expression.new('binary', attrs)
    end

    def parse_cast_expression
      expect_token(:maek)
      attrs = { being_casted: parse_expression }
      expect_token(:a)
      attrs[:to] = expect_token(:noob, :troof, :numbr, :numbar, :yarn)[:type]
      Ast::Expression.new('cast', attrs)
    end

    def parse_constant_expression
      token = expect_token(:boolean, :integer, :float, :string)
      Ast::Expression.new('constant', { vtype: token[:type], value: token[:data] })
    end

    # Identifier expression represents two types of expressions:
    #   variable expression: returns value of variable
    #   function call expression: returns value of function call
    def parse_identifier_expression
      name = expect_token(:identifier)[:data]
      begin
        function = self.functions.fetch(name)
        # Function call
        attrs = { name: name, parameters: [] }
        function.size.times do |c|
          expr_name = next_expression
          if expr_name.nil?
            msg = "Function '%s' expects %d arguments, %d passed" % [name, function.size, c]
            raise ParserError, msg
          end
          attrs[:parameters] << parse_expression(expr_name)
        end
        return Ast::Expression.new('function', attrs)
      rescue KeyError
        # Variable name
        return Ast::Expression.new('variable', name: name)
      end
    end

    def parse_nary_expression
      attrs = { operator: expect_token(:all_of, :any_of, :smoosh)[:type] }
      attrs[:expressions] = [parse_expression]
      while true
        @tokenizer.next if @tokenizer.peek[:type] == :an
        @tokenizer.unpeek
        name = next_expression
        if name.nil? then break else attrs[:expressions] << parse_expression(name) end
      end
      # We need either MKAY or Newline here, but
      # should consume only MKAY if present
      token = @tokenizer.peek
      unless [:mkay, :newline].include?(token[:type])
        raise UnexpectedTokenError, token
      end
      @tokenizer.next if token[:type] == :mkay
      @tokenizer.unpeek
      Ast::Expression.new('nary', attrs)
    end

    def parse_unary_expression
      expect_token(:not)
      Ast::Expression.new('unary', { expression: parse_expression } )
    end
  end
end
