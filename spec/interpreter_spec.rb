require 'minitest/autorun'
require 'layo'

include Layo

describe Interpreter do
  before do
    @interpreter = Interpreter.new
    @interpreter.output = StringIO.new
  end

  it "should correctly interpret test programs" do
    mask = File.join(File.dirname(__FILE__), 'source', '**', '*.lol')
    Dir.glob(mask).each do |source_filename|
      lexer = Lexer.new(File.new(source_filename))
      lexer.input.set_encoding(Encoding::UTF_8)
      parser = Parser.new(Tokenizer.new(lexer))
      @interpreter.output.string = ''

      # Supply input stream if provided
      if File.exist?(infile = source_filename[0..-4] + 'in')
        infile = File.new(infile)
        @interpreter.input = infile
      end

      # Get contents of output file (if provided) to assert later
      if File.exist?(outfile = source_filename[0..-4] + 'out')
        expected_output = File.open(outfile) do |file|
          file.read
        end
      else
        expected_output = nil
      end

      # Execute the program
      begin
        @interpreter.interpret(parser.parse)
      rescue RuntimeError, SyntaxError => e
        puts "Error interpreting #{source_filename}"
        puts e.message
      end

      # Assertions
      if expected_output
        assert_equal expected_output, @interpreter.output.string, "File: #{source_filename}"
      end

      # Cleanup
      lexer.input.close
      infile.close if infile.instance_of?(File)
    end
  end

  describe "#eval_print_stmt" do
    it "should print trailing newline" do
      string = Ast::Expression.new('constant', { vtype: :string, value: "a\n" })
      stmt = Ast::Statement.new('print', {
        expressions: [string], suppress: false
      })

      @interpreter.eval_print_stmt(stmt)

      @interpreter.output.string.must_equal "a\n\n"
    end
  end
end
