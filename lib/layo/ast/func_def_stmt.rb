module Layo::Ast
  class FuncDefStmt < Stmt
    attr_reader :name, :args, :block

    def initialize(name, args, block)
      @name, @args, @block = name, args, block
    end
  end
end
