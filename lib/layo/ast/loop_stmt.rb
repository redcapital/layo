module Layo::Ast
  class LoopStmt < Stmt
    attr_reader :label, :loop_update, :loop_guard

    def initialize(label, loop_update, loop_guard)
      @label, @loop_update, @loop_guard = label, loop_update, loop_guard
    end
  end
end
