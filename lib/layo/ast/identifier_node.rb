module Layo::Ast
  class IdentifierNode < Node
    attr_reader :data
    def initialize(data)
      @data = data
    end
  end
end
