module Layo::Ast
  class FuncCallExpr < Expr
    attr_reader :name, :expr_list

    def initialize(name, expr_list)
      @name, @expr_list = name, expr_list
    end
  end
end
