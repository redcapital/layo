module Layo
  class UnexpectedTokenError < SyntaxError
    def initialize(token)
      super(token[:line], token[:pos], "Unexpected token #{token2str(token)}")
    end

    def token2str(token)
      result = "'#{token[:type].to_s}'"
      result << " (#{token[:data].to_s})" if token.has_key?(:data)
      result
    end
  end
end
