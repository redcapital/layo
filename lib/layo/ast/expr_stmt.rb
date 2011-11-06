module Layo::Ast
  class ExprStmt < Stmt
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end
  end
end
