module Layo::Ast
  class Type < Node
    attr_reader :data
    def initialize(data)
      @data = data
    end
  end
end
