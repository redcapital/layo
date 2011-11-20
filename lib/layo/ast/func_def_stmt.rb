module Layo::Ast
  class FuncDefStmt < Stmt
    attr_reader :name, :args_def, :block

    def initialize(name, args_def, block)
      @name, @args_def, @block = name, args_def, block
    end
  end
end
