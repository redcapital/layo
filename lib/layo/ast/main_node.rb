module Layo::Ast
  class MainNode < Node
    attr_accessor :version, :block
    def initialize(version, block)
      @version, @block = version, block
    end
  end
end
