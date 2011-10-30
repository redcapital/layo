module Layo::Ast
  class ConstantNode < Node
    attr_accessor :type, :value
    def initialize(type, value = nil)
      @type, @value = type, value
    end
  end
end
