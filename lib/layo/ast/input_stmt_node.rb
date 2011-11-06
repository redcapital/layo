module Layo::Ast
  class InputStmtNode < Node
    attr_reader :identifier

    def initialize(identifier)
      @identifier = identifier
    end
  end
end
