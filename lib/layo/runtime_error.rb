module Layo
  class RuntimeError < ::RuntimeError
    attr_accessor :line

    def to_s
      super << " on line #{@line}"
    end
  end
end
