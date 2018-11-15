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
    def satisfied?(rule_execution)
      !!@block.call(rule_execution.user, rule_execution.object, rule_execution)
    end

  end
end
