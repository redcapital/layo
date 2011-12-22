module Layo::Ast
  class CastStmt < Stmt
    attr_reader :identifier, :type

    def initialize(identifier, type)
      @identifier, @type = identifier, type
    end
  end
end
