module Layo::Ast
  class LoopGuard < Node
    attr_reader :condition_type, :condition

    def initialize(condition_type, condition)
      @condition_type, @condition = condition_type, condition
    end
  end
end
