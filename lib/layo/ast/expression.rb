module Layo::Ast
  class Expression < Node
    attr_accessor :type

    def initialize(type, args = {})
      @type = type
      super(args)
    end

    def ==(other)
      @type == other.type && super(other)
    end
  end
end
