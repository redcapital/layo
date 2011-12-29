module Layo
  class SyntaxError < RuntimeError
    def initialize(line_no, pos, message)
      super "Syntax error at line #{line_no}, pos #{pos}: #{message}"
    end
  end
end
