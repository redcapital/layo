module Layo
  class Tokenizer
    include Peekable
    # Instance of Layo::Lexer
    attr_accessor :lexer

    def initialize(lexer)
      @lexer = lexer
      init_token_table
      reset
    end

    def reset
      @lexer.reset
      super
    end

    def try(*types)
      index = @peek_index
      result = true
      types.each do |type|
        unless peek[:type] == type
          result = false
          break
        end
      end
      @peek_index = index
      result
    end

    def init_token_table
      @token_table = {:list => {}}
      ['HAI', 'KTHXBYE', 'NOOB', 'TROOF', 'NUMBR', 'NUMBAR',
        'YARN', 'I HAS A', 'ITZ', 'R', 'SUM OF', 'DIFF OF', 'PRODUKT OF',
        'QUOSHUNT OF', 'MOD OF', 'BIGGR OF', 'SMALLR OF', 'BOTH OF', 'EITHER OF',
        'WON OF', 'NOT', 'ALL OF', 'ANY OF', 'BOTH SAEM', 'DIFFRINT',
        'SMOOSH', 'MAEK', 'IS NOW A', 'A', 'VISIBLE', 'GIMMEH', 'MKAY', 'AN',
        'O RLY?', 'YA RLY', 'NO WAI', 'MEBBE', 'OIC', 'WTF?', 'OMG', 'OMGWTF',
        'GTFO', 'IM IN YR', 'YR', 'TIL', 'WILE', 'IM OUTTA YR', 'UPPIN',
        'NERFIN', 'HOW DUZ I', 'AN YR', 'IF U SAY SO', 'FOUND YR'
      ].each do |t|
        lexemes = t.split(' ')
        root = @token_table[:list]
        lexemes[0..-2].each do |lexeme|
          root[lexeme] = {} unless root.has_key?(lexeme)
          root[lexeme][:list] = {} unless root[lexeme].has_key?(:list)
          root = root[lexeme][:list]
        end
        root[lexemes.last] = {:match => t.gsub(' ', '_').downcase.to_sym}
      end
      @token_table[:list]["\n"] = {:match => :newline}
      @token_table[:list]['!'] = {:match => :exclamation}
    end

    def match_longest(lexeme, root)
      return nil unless root.has_key?(:list) && root[:list].has_key?(lexeme)
      newroot = root[:list][lexeme]
      best_match = newroot.has_key?(:match) ? newroot[:match] : nil
      next_lexeme = @lexer.peek
      unless next_lexeme.nil?
        try_match = match_longest(next_lexeme[0], newroot)
        best_match = try_match unless try_match.nil?
      end
      best_match
    end

    def is_string(lexeme)
      lexeme[0] == '"'
    end

    def is_float(lexeme)
      lexeme =~ /^-?\d+\.\d+$/
    end

    def is_integer(lexeme)
      lexeme =~ /^-?\d+$/
    end

    def is_boolean(lexeme)
      lexeme == 'WIN' or lexeme == 'FAIL'
    end

    def is_identifier(lexeme)
      lexeme =~ /^[a-zA-Z]\w*$/
    end

    def next_item
      lexeme, token = @lexer.next, nil
      if lexeme[0].nil?
        token = {:type => :eof}
      elsif is_string(lexeme[0])
        token = {:type => :string, :data => lexeme[0][1..-2]}
      elsif is_integer(lexeme[0])
        token = {:type => :integer, :data => lexeme[0].to_i}
      elsif is_float(lexeme[0])
        token = {:type => :float, :data => lexeme[0].to_f}
      elsif is_boolean(lexeme[0])
        token = {:type => :boolean, :data => (lexeme[0] == 'WIN')}
      else
        # Try to match keyword
        token_type = match_longest(lexeme[0], @token_table)
        unless token_type.nil?
          token = {:type => token_type}
          # Consume all peeked lexemes
          token_type.to_s.count('_').times { @lexer.next }
        else
          # Try to match identifier
          if is_identifier(lexeme[0])
            token = {:type => :identifier, :data => lexeme[0]}
          end
        end
      end
      raise UnknownTokenError.new(lexeme) if token.nil?
      token.merge(:line => lexeme[1], :pos => lexeme[2])
    end
  end
end
