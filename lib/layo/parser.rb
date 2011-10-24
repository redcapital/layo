module Layo
  class Parser
    attr_accessor :tokenizer

    def initialize(tokenizer)
      @tokenizer = tokenizer
    end

    def parse
      expect(:hai)
      version = expect(:float)
      expect(:newline)
      block_node = parse_block
      expect(:eof)
      Ast::MainNode.new(version[:data], block_node)
    end

    def expect(type)
      token = @tokenizer.next
      raise UnexpectedTokenError(token) unless token[:type] == type
      token
    end

    # BlockNode ::= StmtNode *
    def parse_block
    end
  end
end
