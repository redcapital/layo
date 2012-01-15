module Layo
  class Interpreter < BaseInterpreter
    # Interprets program given as an AST node
    def interpret(program)
      # We should gather all function definitions along with their bodies
      # beforehand so we could call them wherever a call appears
      init_tables
      program.block.each do |statement|
        if statement.type == 'function'
          @functions[statement.name] = {
            args: statement.args, block: statement.block
          }
        end
      end
      eval_program(program)
    end

    def eval_program(program)
      with_guard { eval_block(program.block) }
    end
  end
end
