module Layo::Ast
  class VariableExpr < Expr
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end
end
