module Layo
  class SyntaxError < RuntimeError
    attr_accessor :line, :pos

    def initialize(line, pos, msg)
      super(msg)
      @line, @pos = line, pos
    end

    def to_s
      super << " on line #{@line}, character #{@pos}"
    end
  end
end
