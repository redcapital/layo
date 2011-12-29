module Layo
  class UnknownTokenError < SyntaxError
    def initialize(lexeme)
      super lexeme[1], lexeme[2], "Unknown token '#{lexeme[0]}'"
    end
  end
end
