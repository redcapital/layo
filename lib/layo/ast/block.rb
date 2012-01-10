module Layo::Ast
  class Block < Node
    attr_reader :statement_list

    def initialize(statement_list = [])
      @statement_list = statement_list
    end

    def each
      @statement_list.each { |stmt| yield(stmt) }
    end
  end
end
