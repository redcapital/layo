module Layo::Ast
  class SwitchStmtNode < StmtNode
    attr_reader :case_list, :default_case

    def initialize(case_list, default_case)
      @case_list, @default_case = case_list, default_case
    end
  end
end
