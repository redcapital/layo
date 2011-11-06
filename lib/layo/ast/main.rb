module Layo::Ast
  class Main < Node
    attr_accessor :version, :block
    def initialize(version, block)
      @version, @block = version, block
    end
  end
end
