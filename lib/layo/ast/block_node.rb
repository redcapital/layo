module Layo::Ast
  class BlockNode < Node
    attr_accessor :stmt_list
    def initialize(stmt_list = [])
      @stmt_list = stmt_list
    end
  end
end
