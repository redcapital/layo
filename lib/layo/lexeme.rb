module Layo
  class Lexeme
    attr_accessor :data, :line, :position

    def initialize(data, line, position)
      @data = data
      @line = line
      @position = position
    end

    def ==(other)
      @data == other.data && @line == other.line && @position == other.position
    end
  end
end
