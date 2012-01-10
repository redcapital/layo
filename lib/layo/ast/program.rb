module Layo::Ast
  class Program < Node
    attr_reader :version, :block

    def initialize(version, block)
      @version, @block = version, block
    end
  end
end
