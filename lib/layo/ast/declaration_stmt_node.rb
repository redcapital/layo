module Layo::Ast
  class DeclarationStmtNode < Node
    attr_reader :identifier, :initialization

    def initialize(identifier, initialization)
      @identifier, @initialization = identifier, initialization
    end
  end
end
