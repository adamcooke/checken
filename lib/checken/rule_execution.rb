module Checken
  class RuleExecution

    attr_reader :rule
    attr_reader :user
    attr_reader :object
    attr_reader :memo

    def initialize(rule, user, object = nil)
      @rule = rule
      @user = user
      @object = object
      @memo = {}
    end

    def satisfied?
      @rule.satisfied?(self)
    end

  end
end
