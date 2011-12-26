module Layo::Ast
  class Statement < Node
    attr_accessor :type

    def initialize(type, args = {})
      @type = type
      super(args)
    end
  end
end
