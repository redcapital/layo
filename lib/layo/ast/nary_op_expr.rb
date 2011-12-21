module Layo::Ast
  class NaryOpExpr < Expr
    attr_reader :type, :expr_list

    def initialize(type, expr_list)
      @type, @expr_list = type, expr_list
    end
  end
end
