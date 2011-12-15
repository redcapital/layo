module Layo
  module Peekable
    attr_accessor :peek_index

    def reset
      @peek_index, @items = -1, []
    end

    def peek
      @peek_index += 1
      while @items.length <= @peek_index
        @items << next_item
      end
      @items[@peek_index]
    end

    def unpeek
      @peek_index -= 1 if @peek_index > -1
    end

    def next
      @peek_index = -1
      @items << next_item if @items.empty?
      @items.shift
    end

    def reset_peek
      @peek_index = -1
    end
  end
end
