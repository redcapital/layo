module Layo
  class InteractiveInterpreter < BaseInterpreter
    attr_accessor :parser

    def initialize(parser)
      @parser = parser
      super
    end

    def interpret
      init_tables
      @stmt_line = 1
      @output.puts 'Press Control-C to exit'
      while true
        begin
          @output.print ' > '
          break if @parser.tokenizer.try(:eof)
          begin
            statement = @parser.parse_statement
            with_guard { send("eval_#{statement.type}_stmt", statement) }
          end until @parser.tokenizer.lexer.buffer_empty?
        rescue Layo::SyntaxError => e
          @parser.tokenizer.reset
          @parser.tokenizer.lexer.reset
          $stderr.puts "Syntax error: #{e}"
        rescue Layo::RuntimeError => e
          $stderr.puts "Runtime error: #{e}"
        rescue Interrupt
          @output.puts 'Exiting'
          break
        end
      end
    end

    def eval_function_stmt(stmt)
      if @functions.has_key?(stmt.name)
        raise RuntimeError, "Function '#{stmt.name}' is already declared"
      end
      @functions[stmt.name] = { args: stmt.args, block: stmt.block }
    end
  end
end
