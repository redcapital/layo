module Layo::Ast
  class ReturnStmtNode < Node
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end
  end
end
