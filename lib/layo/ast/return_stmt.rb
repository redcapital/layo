module Layo::Ast
  class ReturnStmt < Node
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end
  end
end
