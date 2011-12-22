module Layo::Ast
  class DeclarationStmt < Node
    attr_reader :identifier, :initialization

    def initialize(identifier, initialization)
      @identifier, @initialization = identifier, initialization
    end
  end
end
