module Layo::Ast
  class CastExpr < Expr
    attr_reader :expr, :type

    def initialize(expr, type)
      @expr, @type = expr, type
    end
  end
end
