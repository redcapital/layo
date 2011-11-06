module Layo::Ast
  class CastStmtNode < StmtNode
    attr_reader :identifier, :type

    def initialize(identifier, type)
      @identifier, @type = identifier, type
    end
  end
end
