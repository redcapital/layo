require 'minitest/autorun'
require 'layo'

include Layo

describe Interpreter do
  before do
    @lexer = Lexer.new
    @output = StringIO.new
    @interpreter = Interpreter.new(Parser.new(Tokenizer.new(@lexer)))
    @interpreter.output = @output
  end

  it "should correctly interpret test programs" do
    mask = File.join(File.dirname(__FILE__), 'source', '**', '*.lol')
    Dir.glob(mask).each do |source_filename|
      # Reset everything
      @lexer.input = File.new(source_filename)
      @interpreter.parser.reset
      @output.string = ''

      # Supply input stream if provided
      if File.exist?(infile = source_filename[0..-4] + 'in')
        infile = File.new(infile)
        @interpreter.input = infile
      end

      # Get contents of output file (if provided) to assert later
      if File.exist?(outfile = source_filename[0..-4] + 'out')
        output = File.open(outfile) do |file|
          file.read
        end
      else
        output = nil
      end

      # Execute the program
      @interpreter.interpret

      # Assertions
      unless output.nil?
        assert_equal output, @output.string, "File: #{source_filename}"
      end

      # Cleanup
      @lexer.input.close
      infile.close if infile.instance_of?(File)
    end
  end
end
