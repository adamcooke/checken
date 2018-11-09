module Checken
  class Rule

    attr_reader :key

    def initialize(key, &block)
      @key = key
      @block = block
    end

    # Are we satisifed that this rule's condition is true?
    #
    # @param user [Checken::User]
    # @return [Boolean]
    def satisfied?(user, object = nil)
      !!@block.call(user, object)
    end

  end
end
