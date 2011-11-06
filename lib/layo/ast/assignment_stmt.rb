module Layo::Ast
  class AssignmentStmt < Node
    attr_reader :identifier, :expr

    def initialize(identifier, expr)
      @identifier, @expr = identifier, expr
    end
  end
end
