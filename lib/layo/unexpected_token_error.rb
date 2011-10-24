module Layo
  class UnexpectedTokenError < SyntaxError
    def initialize(token)
      super token[:line], token[:pos], "Unexpected token - #{token2str(token)}"
    end

    def token2str(token)
      result = "type: #{token[:type]}"
      token.has_key?(:data) ? result << ", data: #{token[:data].to_s}" : result
    end
  end
end
