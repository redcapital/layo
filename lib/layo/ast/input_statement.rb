module Layo::Ast
  class InputStmt < Node
    attr_reader :identifier

    def initialize(identifier)
      @identifier = identifier
    end
  end
end
