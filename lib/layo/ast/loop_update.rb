module Layo::Ast
  class LoopUpdate < Node
    attr_reader :update_op, :identifier

    def initialize(update_op, identifier)
      @update_op, @identifier = update_op, identifier
    end
  end
end
