module Checken
  class IncludedRule

    attr_reader :key
    attr_reader :block

    def initialize(key, &block)
      @key = key
      @block = block
    end

  end
end
