module Layo::Ast
  class IfThenElseStmt < Stmt
    attr_reader :block, :elseif_list, :else_block

    def initialize(block, elseif_list, else_block)
      @block, @elseif_list, @else_block = block, elseif_list, else_block
    end
  end
end
