module Layo::Ast
  class UnaryOpExpr < Expr
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end
  end
end
