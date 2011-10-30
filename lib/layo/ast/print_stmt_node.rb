module Layo::Ast
  class PrintStmtNode < Node
    attr_reader :expr_list, :suppress

    def initialize(expr_list, suppress)
      @expr_list, @suppress = expr_list, suppress
    end
  end
end
