module Layo::Ast
  class AssignmentStmt < Stmt
    attr_reader :identifier, :expr

    def initialize(identifier, expr)
      @identifier, @expr = identifier, expr
    end
  end
end
