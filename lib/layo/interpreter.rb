module Layo
  class Interpreter
    attr_accessor :parser, :input, :output

    def initialize(parser, input = STDIN, output = STDOUT)
      @parser, @input, @output = parser, input, output
    end

    def interpret
      @functions = {}
      @parser.parse_function_declarations
      main = @parser.parse
      main.block.each do |statement|
        if statement.type == 'function'
          @functions[statement.name] = {
            args: @parser.functions[statement.name],
            block: statement.block
          }
        end
      end
      eval_main(main)
    end

    def create_variable_table
      table = Hash.new do |hash, key|
        raise RuntimeError, "Variable #{key} is not defined"
      end
      table['IT'] = {:type => :noob, :value => :nil}
      return table
    end

    def eval_main(main)
      @vtable = create_variable_table
      eval_block(main.block)
    end

    def eval_block(block)
      block.each do |stmt|
        eval_stmt(stmt)
      end
    end

    def eval_stmt(stmt)
      method = "eval_#{stmt.type}_stmt"
      send method.to_sym, stmt
    end

    def eval_assignment_stmt(stmt)
      var = @vtable[stmt.identifier]
      @vtable[stmt.identifier] = eval_expr(stmt.expr)
    end

    def eval_break_stmt(stmt)
      throw :break, {:type => :noob, :value => nil}
    end

    def eval_cast_stmt(stmt)
      var = @vtable[stmt.identifier]
      var[:value] = cast(var, stmt.cast_to.data, false)
      var[:type] = stmt.cast_to.data
    end

    def eval_declaration_stmt(stmt)
      if @vtable.has_key?(stmt.identifier)
        raise RuntimeError, "Variable #{stmt.identifier} is already declared"
      end
      @vtable[stmt.identifier] = {:type => :noob, :value => nil}
      unless stmt.initialization.nil?
        @vtable[stmt.identifier] = eval_expr(stmt.initialization)
      end
    end

    def eval_expression_stmt(stmt)
      @vtable['IT'] = eval_expr(stmt.expr)
    end

    def eval_function_stmt(stmt); end

    def eval_condition_stmt(stmt)
      if cast(@vtable['IT'], :troof)
        # if block
        eval_block(stmt.block)
      else
        # else if blocks
        condition_met = false
        stmt.elseif_list.each do |elseif|
          condition = eval_expr(elseif.expr)
          if condition_met = cast(condition, :troof)
            eval_block(elseif.block)
            break
          end
        end
        unless condition_met || stmt.else_block.nil?
          # else block
          eval_block(stmt.else_block)
        end
      end
    end

    def eval_input_stmt(stmt)
      @vtable[stmt.identifier] = {:type => :yarn, :value => @input.gets}
    end

    def eval_loop_stmt(stmt)
      update, guard = stmt.loop_update, stmt.loop_guard
      unless update.nil?
        if @vtable.has_key?(update.identifier[:data])
          var_backup = @vtable[update.identifier[:data]]
        end
        @vtable[update.identifier[:data]] = {:type => :numbr, :value => 0}
        update_op = if update.update_op[:type] == :uppin
          lambda { @vtable[update.identifier[:data]][:value] += 1 }
        elsif update.update_op[:type] == :nerfin
          lambda { @vtable[update.identifier[:data]][:value] -= 1 }
        else
          lambda {
            @vtable[update.identifier[:data]] = call_func(update.update_op[:data], [@vtable[update.identifier[:data]]])
          }
        end
      end

      catch :break do
        while true
          unless guard.nil?
            condition_met = cast(eval_expr(guard.condition), :troof)
            if (guard.condition_type == :wile && !condition_met) or
               (guard.condition_type == :til && condition_met)
               throw :break
            end
          end
          eval_block(stmt.block)
          update_op.call if update_op
        end
      end
      unless update.nil? || var_backup.nil?
        @vtable[update.identifier[:data]] = var_backup
      end
    end

    def eval_print_stmt(stmt)
      text = ''
      # todo rewrite using map or similar
      stmt.expr_list.each do |expr|
        text << cast(eval_expr(expr), :yarn)
      end
      if stmt.suppress
        @output.print text
      else
        @output.puts text
      end
    end

    def eval_return_stmt(stmt)
      throw :break, eval_expr(stmt.expr)
    end

    def eval_switch_stmt(stmt)
      case_found = false
      it = @vtable['IT']
      stmt.case_list.each do |kase|
        unless case_found
          expr = eval_expr(kase.expr)
          val = cast(expr, it[:type])
          if it[:value] == val
            case_found = true
          end
        end
        if case_found
          breaked = true
          catch :break do
            eval_block(kase.block)
            breaked = false
          end
          break if breaked
        end
      end
      unless case_found or stmt.default_case.nil?
        catch :break do
          eval_block(stmt.default_case)
        end
      end
    end

    def cast(var, to, implicit = true)
      return var[:value] if var[:type] == to
      return nil if to == :noob
      case var[:type]
        when :noob
          if implicit && to != :troof
            raise RuntimeError, "noob cannot be implicitly cast into #{to.to_s.upcase}"
          end
          return false if to == :troof
          return 0 if to == :numbr
          return 0.0 if to == :numbar
          return ''
        when :troof
          return (var[:value] ? 1 : 0) if to == :numbr
          return (var[:value] ? 1.0 : 0.0) if to == :numbar
          return (var[:value] ? 'WIN' : 'FAIL')
        when :numbr
          return (var[:value].zero? ? false : true) if to == :troof
          return var[:value].to_f if to == :numbar
          return var[:value].to_s
        when :numbar
          return (var[:value].zero? ? false : true) if to == :troof
          return var[:value].to_int if to == :numbr
          return var[:value].to_s
        else
          return !var[:value].empty? if to == :troof
          # todo check if string is a number using regex
          return var[:value].to_i if to == :numbr
          return var[:value].to_f
      end
    end

    def eval_expr(expr)
      klass = expr.class.name
      method = "eval_#{klass[klass.rindex('::') + 2..klass.length - 5].downcase}_expr"
      send method, expr
    end

    def eval_binaryop_expr(expr)
      l = eval_expr(expr.expr1)
      r = eval_expr(expr.expr2)
      methods = {
        :sum_of => :+, :diff_of => :-, :produkt_of => :*, :quoshunt_of => :/,
        :mod_of => :modulo, :both_of => :&, :either_of => :|, :won_of => :^,
        :both_saem => :==, :diffrint => :!=
      }
      case expr.type
        when :sum_of, :diff_of, :produkt_of, :quoshunt_of, :mod_of, :biggr_of, :smallr_of
          # todo need to try casting string to numbar first and check type after that
          type = (l[:type] == :numbar or r[:type] == :numbar) ? :numbar : :numbr
          l, r = cast(l, type), cast(r, type)
          if expr.type == :biggr_of
            value = [l, r].max
          elsif expr.type == :smallr_of
            value = [l, r].min
          else
            value = l.send(methods[expr.type], r)
          end
        when :both_saem, :diffrint
          type = :troof
          if (l[:type] == :numbr && r[:type] == :numbar) ||
            (l[:type] == :numbar && r[:type] == :numbr)
            l, r = cast(l, :numbar), cast(r, :numbar)
          elsif l[:type] != r[:type]
            raise RuntimeError, 'Operands must have same type'
          end
          value = l.send(methods[expr.type], r)
        else
          type = :troof
          l, r = cast(l, :troof), cast(r, :troof)
          value = l.send(methods[expr.type], r)
      end
      return {:type => type, :value => value}
    end

    def eval_cast_expr(expr)
      casted_expr = eval_expr(expr.expr)
      return {:type => expr.type.data, :value => cast(casted_expr, expr.type.data, false)}
    end

    def eval_constant_expr(expr)
      # todo use consistent type names everywhere (i.e. only troof instead of boolean)
      mapping = {:boolean => :troof, :string => :yarn, :integer => :numbr, :float => :numbar}
      # todo string interpolation
      return {:type => mapping[expr.type], :value => expr.value}
    end

    def eval_funccall_expr(expr)
      arguments = []
      expr.expr_list.each do |arg|
        arguments << eval_expr(arg)
      end
      call_func(expr.name, arguments)
    end

    def call_func(name, arguments)
      function = @functions[name]
      old_table = @vtable
      @vtable = create_variable_table
      function[:args].each_index do |index|
        @vtable[function[:args][index]] = arguments[index]
      end
      returned = true
      retval = catch :break do
        eval_block(function[:block])
        returned = false
      end
      retval = @vtable['IT'] unless returned
      @vtable = old_table
      return retval
    end

    def eval_naryop_expr(expr)
      case expr.type
        when :all_of
          type, value = :troof, true
          expr.expr_list.each do |operand|
            unless cast(eval_expr(operand), :troof)
              value = false
              break
            end
          end
        when :any_of
          type, value = :troof, false
          expr.expr_list.each do |operand|
            if cast(eval_expr(operand), :troof)
              value = true
              break
            end
          end
        when :smoosh
          type, value = :yarn, ''
          expr.expr_list.each do |operand|
            value << cast(eval_expr(operand), :yarn)
          end
      end
      return {:type => type, :value => value}
    end

    def eval_unaryop_expr(expr)
      # the only unary op in LOLCODE is NOT
      return {:type => :troof, :value => !cast(eval_expr(expr.expr), :troof)}
    end

    def eval_variable_expr(expr)
      return @vtable[expr.name]
    end
  end
end
