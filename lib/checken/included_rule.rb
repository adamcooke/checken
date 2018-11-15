module Checken
  class IncludedRule

    attr_reader :key
    attr_reader :block
    attr_accessor :condition

    def initialize(key, &block)
      @key = key
      @block = block
    end

  end
end
