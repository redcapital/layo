module Layo::Ast
  class Block < Node
    attr_reader :stmt_list

    def initialize(stmt_list = [])
      @stmt_list = stmt_list
    end
  end
end
