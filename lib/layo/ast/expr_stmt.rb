module Layo::Ast
  class ExprStmt < StmtNode
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end
  end
end
