module Layo::Ast
  class TypeNode < Node
    attr_reader :data
    def initialize(data)
      @data = data
    end
  end
end
