module Layo::Ast
  class BinaryOpExpr < Expr
    attr_reader :type, :expr1, :expr2

    def initialize(type, expr1, expr2)
      @type, @expr1, @expr2 = type, expr1, expr2
    end
  end
end
