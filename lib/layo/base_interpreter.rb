module Layo
  class BaseInterpreter
    attr_accessor :input, :output

    def initialize(input = STDIN, output = STDOUT)
      @input, @output = input, output
    end

    def create_variable_table
      table = Hash.new do |hash, key|
        raise RuntimeError, "Variable '#{key}' is not declared"
      end
      table['IT'] = { type: :noob, value: nil}
      table
    end

    # Initializes empty function and variable tables
    def init_tables
      @functions = {}
      @vtable = create_variable_table
    end

    # Runs piece of code inside guard to catch :break and :return thrown by
    # illegal statements. Also assigns line numbers to RuntimeError's
    def with_guard(&block)
      begin
        illegal = true
        catch(:break) do
          catch(:return) do
            block.call
            illegal = false
          end
          raise RuntimeError, "Illegal return statement" if illegal
        end
        raise RuntimeError, "Illegal break statement" if illegal
      rescue RuntimeError => e
        e.line = @stmt_line
        raise e
      end
    end

    def eval_block(block)
      block.each do |stmt|
        @stmt_line = stmt.line
        send("eval_#{stmt.type}_stmt", stmt)
      end
    end

    def eval_assignment_stmt(stmt)
      # We should access by variable name first to ensure that it is defined
      @vtable[stmt.identifier]
      @vtable[stmt.identifier] = eval_expr(stmt.expression)
    end

    def eval_break_stmt(stmt)
      throw :break
    end

    def eval_cast_stmt(stmt)
      var = @vtable[stmt.identifier]
      var[:value] = cast(var, stmt.to, false)
      var[:type] = stmt.to
    end

    def eval_declaration_stmt(stmt)
      if @vtable.has_key?(stmt.identifier)
        raise RuntimeError, "Variable '#{stmt.identifier}' is already declared"
      end
      @vtable[stmt.identifier] = { type: :noob, value: nil }
      unless stmt.initialization.nil?
        @vtable[stmt.identifier] = eval_expr(stmt.initialization)
      end
    end

    def eval_expression_stmt(stmt)
      @vtable['IT'] = eval_expr(stmt.expression)
    end


    def eval_condition_stmt(stmt)
      if cast(@vtable['IT'], :troof)
        # if block
        eval_block(stmt.then)
      else
        # else if blocks
        condition_met = false
        stmt.elseif.each do |elseif|
          condition = eval_expr(elseif[:condition])
          if condition_met = cast(condition, :troof)
            eval_block(elseif[:block])
            break
          end
        end
        unless condition_met || stmt.else.nil?
          # else block
          eval_block(stmt.else)
        end
      end
    end

    def eval_input_stmt(stmt)
      @vtable[stmt.identifier] = { type: :yarn, value: @input.gets }
    end

    def eval_loop_stmt(stmt)
      unless stmt.op.nil?
        # Backup any local variable if its name is the same as the counter
        # variable's name
        if @vtable.has_key?(stmt.counter)
          var_backup = @vtable[stmt.counter]
        end
        @vtable[stmt.counter] = { type: :numbr, value: 0 }
        update_op = if stmt.op == :uppin
          lambda { @vtable[stmt.counter][:value] += 1 }
        elsif stmt.op == :nerfin
          lambda { @vtable[stmt.counter][:value] -= 1 }
        else
          lambda {
            @vtable[stmt.counter] = call_func(stmt.op, [@vtable[stmt.counter]])
          }
        end
      end

      catch :break do
        while true
          unless stmt.guard.nil?
            condition_met = cast(eval_expr(stmt.guard[:expression]), :troof)
            if (stmt.guard[:type] == :wile && !condition_met) or
               (stmt.guard[:type] == :til && condition_met)
               throw :break
            end
          end
          eval_block(stmt.block)
          update_op.call if update_op
        end
      end
      # Restore backed up variable
      unless stmt.op.nil? || var_backup.nil?
        @vtable[stmt.counter] = var_backup
      end
    end

    def eval_print_stmt(stmt)
      text = ''
      # todo rewrite using map or similar
      stmt.expressions.each do |expr|
        text << cast(eval_expr(expr), :yarn)
      end
      text << "\n" unless stmt.suppress
      @output.print(text)
    end

    def eval_return_stmt(stmt)
      throw :return, eval_expr(stmt.expression)
    end

    def eval_switch_stmt(stmt)
      stmt.cases.combination(2) do |c|
        raise RuntimeError, 'Literals must be unique' if c[0] == c[1]
      end
      case_found = false
      it = @vtable['IT']
      stmt.cases.each do |kase|
        unless case_found
          literal = eval_expr(kase[:expression])
          if it == literal
            case_found = true
          end
        end
        if case_found
          breaked = true
          catch :break do
            eval_block(kase[:block])
            breaked = false
          end
          break if breaked
        end
      end
      unless case_found || stmt.default.nil?
        catch :break do
          eval_block(stmt.default)
        end
      end
    end

    # Casts given variable 'var' into type 'to'
    # Returns only value part of the variable, type will be 'to' anyway
    def cast(var, to, implicit = true)
      return var[:value] if var[:type] == to
      return nil if to == :noob
      case var[:type]
        when :noob
          if implicit && to != :troof
            raise RuntimeError, "NOOB cannot be implicitly cast into #{to.to_s.upcase}"
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
          # Truncate to 2 digits after decimal point
          return ((var[:value] * 100).floor / 100.0).to_s
        else
          return !var[:value].empty? if to == :troof
          if to == :numbr
            return var[:value].to_i if var[:value].lol_integer?
            raise RuntimeError, "'#{var[:value]}' is not a valid integer"
          end
          return var[:value].to_f if var[:value].lol_float?
          raise RuntimeError, "'#{var[:value]}' is not a valid float"
      end
    end

    def eval_expr(expr)
      send("eval_#{expr.type}_expr", expr)
    end

    def eval_binary_expr(expr)
      l = eval_expr(expr.left)
      r = eval_expr(expr.right)
      methods = {
        :sum_of => :+, :diff_of => :-, :produkt_of => :*, :quoshunt_of => :/,
        :mod_of => :modulo, :both_of => :&, :either_of => :|, :won_of => :^,
        :both_saem => :==, :diffrint => :!=
      }
      case expr.operator
        when :sum_of, :diff_of, :produkt_of, :quoshunt_of, :mod_of, :biggr_of, :smallr_of
          type = l[:type] == :numbar || r[:type] == :numbar ||
            (l[:type] == :yarn && l[:value].lol_float?) ||
            (r[:type] == :yarn && r[:value].lol_float?) ? :numbar : :numbr
          l, r = cast(l, type), cast(r, type)
          if expr.operator == :biggr_of
            value = [l, r].max
          elsif expr.operator == :smallr_of
            value = [l, r].min
          else
            value = l.send(methods[expr.operator], r)
          end
        when :both_saem, :diffrint
          type = :troof
          if (l[:type] == :numbr && r[:type] == :numbar) ||
            (l[:type] == :numbar && r[:type] == :numbr)
            l, r = cast(l, :numbar), cast(r, :numbar)
          elsif l[:type] != r[:type]
            raise RuntimeError, 'Operands must have same type'
          end
          value = l.send(methods[expr.operator], r)
        else
          type = :troof
          l, r = cast(l, :troof), cast(r, :troof)
          value = l.send(methods[expr.operator], r)
      end
      { type: type, value: value }
    end

    def eval_cast_expr(expr)
      casted_expr = eval_expr(expr.being_casted)
      { type: expr.to, value: cast(casted_expr, expr.to, false) }
    end

    def eval_constant_expr(expr)
      mapping = { boolean: :troof, string: :yarn, integer: :numbr, float: :numbar }
      value = expr.vtype == :string ? interpolate_string(expr.value) : expr.value
      { type: mapping[expr.vtype], value: value }
    end

    def eval_function_expr(expr)
      parameters = []
      expr.parameters.each do |param|
        parameters << eval_expr(param)
      end
      call_func(expr.name, parameters)
    end

    def call_func(name, arguments)
      function = @functions[name]
      # Replace variable table by 'clean' variable table inside functions
      old_table = @vtable
      @vtable = create_variable_table
      function[:args].each_index do |index|
        @vtable[function[:args][index]] = arguments[index]
      end
      retval = nil
      retval = catch :return do
        breaked = true
        catch(:break) do
          eval_block(function[:block])
          breaked = false
        end
        retval = { type: :noob, value: nil } if breaked
      end
      retval = @vtable['IT'] if retval.nil?
      @vtable = old_table
      retval
    end

    def eval_nary_expr(expr)
      case expr.operator
        when :all_of
          type, value = :troof, true
          expr.expressions.each do |operand|
            unless cast(eval_expr(operand), :troof)
              value = false
              break
            end
          end
        when :any_of
          type, value = :troof, false
          expr.expressions.each do |operand|
            if cast(eval_expr(operand), :troof)
              value = true
              break
            end
          end
        when :smoosh
          type, value = :yarn, ''
          expr.expressions.each do |operand|
            value << cast(eval_expr(operand), :yarn)
          end
      end
      { type: type, value: value }
    end

    def eval_unary_expr(expr)
      # the only unary op in LOLCODE is NOT
      { type: :troof, value: !cast(eval_expr(expr.expression), :troof) }
    end

    def eval_variable_expr(expr)
      @vtable[expr.name]
    end

    # Interpolates values of variables in the string
    def interpolate_string(str)
      str.gsub(/:\{([a-zA-Z]\w*)\}/) { cast(@vtable[$1], :yarn, false) }
    end
  end
end
