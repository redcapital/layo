module Layo::Ast
  class FuncDefArgs < Node
    attr_reader :args

    def initialize(args)
      @args = args
    end

    def size
      @args.size
    end

    def each
      @args.each { |arg| yield(arg) }
    end

    def each_index
      @args.each_index { |index| yield(index) }
    end

    def [](index)
      @args[index]
    end
  end
end
