module Layo
  class Parser
    attr_accessor :tokenizer

    def initialize(tokenizer)
      @tokenizer = tokenizer
    end

    def parse
      expect_token(:hai)
      version = expect_token(:float)
      expect_token(:newline)
      block_node = parse_block
      expect_token(:eof)
      Ast::MainNode.new(version[:data], block_node)
    end

    def expect_token(*types)
      token = @tokenizer.next
      raise UnexpectedTokenError, token unless types.include?(token[:type])
      token
    end

    # BlockNode ::= StmtNode *
    def parse_block
      stmts = []
      while stmt_next?
        stmts << parse_stmt
      end
      BlockNode.new(stmts)
    end

    # ConstantNode ::= Boolean | Integer | Float | String
    def parse_constant
      token = expect_token(:boolean, :integer, :float, :string)
      ConstantNode.new(token[:type], token[:data])
    end

    # IdentifierNode ::= :identifier
    def parse_identifier
      token = expect_token(:identifier)
      IdentifierNode.new(token[:data])
    end

    # TypeNode ::= TT_NOOB | TT_TROOF | TT_NUMBR | TT_NUMBAR | TT_YARN
    def parse_type
      token = expect_token(:noob, :troof, :numbr, :numbar, :yarn)
      TypeNode.new(token[:type])
    end

    # CastStmtNode ::= IdentifierNode TT_ISNOWA TypeNode TT_NEWLINE
    def parse_cast_stmt
      identifier = parse_identifier
      expect_token(:is_now_a)
      type = parse_type
      expect_token(:newline)
      CastStmtNode.new(identifier, type)
    end

    # PrintStmtNode ::= TT_VISIBLE ExprNode + [ TT_BANG ] TT_NEWLINE
    def parse_print_stmt
      expect_token(:visible)
      expr_list = [parse_expr]
      while expr_next?
        expr_list << parse_expr
      end
      token = expect_token(:exclamation, :newline)
      suppress = false
      if token[:type] == :exclamation
        expect_token(:newline)
        suppress = true
      end
      PrintStmtNode.new(expr_list, suppress)
    end
  end
end
