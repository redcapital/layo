module Layo::Ast
  class Constant < Node
    attr_reader :type, :value

    def initialize(type, value = nil)
      @type, @value = type, value
    end
  end
end
