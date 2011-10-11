# encoding: UTF-8

module Layo
  class Lexer
    # Input stream. Must be an instance of IO class (File, StringIO)
    attr_accessor :input
    # Current line number (1-based) and position (0-based) of cursor
    attr_reader :pos, :line_no

    def initialize(io = nil)
      self.input = io unless io.nil?
    end

    # Sets input stream and resets variables
    def input=(io)
      @input, @line_no, @last_lexeme = io, 0, "\n"
    end

    def space?(char)
      char == ' ' or char == "\t"
    end

    # Tells whether there is a lexeme delimiter at position pos in current line
    def lexeme_delimiter?(pos)
      @line[pos] == '!' or @line[pos] == ',' or
      @line[pos] == "\n" or space?(@line[pos]) or
      @line[pos] == '…' or @line[pos, 3] == '...'
    end

    # Reads and returns next lexeme
    # returns nil if there is no lexeme left
    def next
      while true
        @line = next_line if @line_no.zero? or @pos > @line.length - 1
        return nil if @line.nil?

        # Skip whitespaces
        while space?(@line[@pos])
          @pos += 1
        end

        # Skip triple dot characters (join lines)
        if @line[@pos, 4] == "...\n" or @line[@pos, 2] == "…\n"
          line_no, pos = @line_no, @pos
          @line, @pos = next_line, 0
          if @line.nil? or @line.strip.empty?
            raise SyntaxError.new(line_no, pos, 'Line continuation may not be followed by an empty line')
          end
          next
        end

        # Skip one line comments
        if @line[@pos, 3] == 'BTW'
          @pos = @line.length + 1
          next
        end
        # and multiline ones
        if @last_lexeme == "\n" && @line[@pos, 4] == 'OBTW'
          tldr_found, line_no, pos = false, @line_no, @pos
          while true
            @line = next_line
            break if @line.nil?
            m = @line.chomp.match(/(^|\s+)TLDR\s*(,|$)/)
            unless m.nil?
              tldr_found = true
              @pos = m.end(0)
              break
            end
          end
          unless tldr_found
            raise SyntaxError.new(line_no, pos, 'Unterminated multiline comment')
          end
          next
        end

        if @line[@pos] == "\n" or @line[@pos] == '!'
          # Handle newline and bang separately
          lexeme = [@line[@pos], @line_no, @pos + 1]
          @pos += 1
        elsif @line[@pos] == ','
          # Comma is a virtual newline
          lexeme = ["\n", @line_no, @pos + 1]
          @pos += 1
        elsif @line[@pos] == '"'
          # Strings begin with "
          # Need to handle empty strings separately
          if @line[@pos + 1] == '"'
            string = '""'
          else
            m = @line.match(/[^:]"/, @pos + 1)
            string = @line[@pos..m.end(0) - 1] unless m.nil?
          end
          # String must be followed by an allowed lexeme delimiter
          if string.nil? or !lexeme_delimiter?(@pos + string.length)
            raise SyntaxError.new(@line_no, @pos, 'Unterminated string constant')
          end
          lexeme = [string, @line_no, @pos + 1]
          @pos = @pos + string.length
        else
          # Grab as much characters as we can until meeting lexeme delimiter
          # Treat what we grabbed as a lexeme
          seq, pos = '', @pos + 1
          until lexeme_delimiter?(@pos)
            seq += @line[@pos]
            @pos += 1
          end
          lexeme = [seq, @line_no, pos]
        end

        break
      end
      @last_lexeme = lexeme[0]
      lexeme
    end

    # Reads and returns next line from input stream. Converts newline
    # character to \n
    # returns nil upon reaching EOF
    def next_line
      line, ch, @pos, @line_no = '', '', 0, @line_no + 1
      until ch == "\r" or ch == "\n" or ch.nil?
        ch = @input.getc
        line += ch unless ch.nil?
      end
      if ch == "\r"
        ch = @input.getc
        @input.ungetc(ch) unless ch == "\n" or ch.nil?
      end
      return nil if line.empty?
      line.chomp << "\n"
    end
  end
end
