module Layo
  class Lexer
    def scan(io)
      lexemes = []
      linenum = 0
      io.each_line do |line|
        linenum += 1
        pos = 0
        line.chomp.each_char do |c|
          pos += 1
          next if space?(c)
          if c == '!'
            lexemes << Lexeme.new('!', linenum, pos)
          elsif c == ','
            lexemes << Lexeme.new(',', linenum, pos)
          end
        end
      end
      lexemes
    end

    def space?(char)
      char == ' ' or char == "\t"
    end
  end
end

