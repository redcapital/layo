module Layo::Ast
  class FuncDefArgs < Node
    attr_reader :args

    def initialize(args)
      @args = args
    end
  end
end
