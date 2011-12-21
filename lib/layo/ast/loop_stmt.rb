module Layo::Ast
  class LoopStmt < Stmt
    attr_reader :label, :loop_update, :loop_guard, :block

    def initialize(label, loop_update, loop_guard, block)
      @label, @loop_update, @loop_guard, @block = label, loop_update, loop_guard, block
    end
  end
end
