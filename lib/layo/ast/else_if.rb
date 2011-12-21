module Layo::Ast
  class ElseIf < Node
    attr_reader :expr, :block

    def initialize(expr, block)
      @expr, @block = expr, block
    end
  end
end
