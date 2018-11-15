require 'spec_helper'
require 'checken/rule'
require 'checken/rule_execution'
require 'checken/schema'

describe Checken::Rule do

  context "#satisfied?" do
    subject(:rule) { }
    it "should return true when the block returns true" do
      rule = Checken::Rule.new('test') { true }
      re = Checken::RuleExecution.new(rule, nil)
      expect(rule.satisfied?(re)).to be true
    end

    it "should return true when the block returns an object other than nil or false" do
      rule = Checken::Rule.new('test') { 1234 }
      re = Checken::RuleExecution.new(rule, nil)
      expect(rule.satisfied?(re)).to be true
    end

    it "should return false when the block returns nil or false" do
      rule = Checken::Rule.new('test') { false }
      re = Checken::RuleExecution.new(rule, nil)
      expect(rule.satisfied?(re)).to be false
    end

    it "should have the user passed through" do
      rule = Checken::Rule.new('test') { |user| user == 1234 }
      expect(rule.satisfied?(Checken::RuleExecution.new(rule, 1234))).to be true
      expect(rule.satisfied?(Checken::RuleExecution.new(rule, 0000))).to be false
    end
  end

end
