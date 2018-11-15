module Checken
  module DSL
    class SetDSL

      attr_reader :rules
      attr_reader :required_object_types
      attr_reader :dependencies
      attr_reader :contexts
      attr_reader :included_rules

      def initialize(group_dsl)
        @group_dsl = group_dsl
        @rules = {}
        @required_object_types = []
        @dependencies = []
        @contexts = []
        @included_rules = {}
      end

      def rule(name, &block)
        @rules[name] = Rule.new(name, &block)
      end

      def include_rule(key, &block)
        @included_rules[key] = IncludedRule.new(key, &block)
      end

      def requires_object(*names)
        names.each do |name|
          @required_object_types << name
        end
      end

      def depends_on(*paths)
        paths.each do |path|
          @dependencies << path
        end
      end

      def context(*contexts)
        contexts.each do |context|
          @contexts << context
        end
      end

      def permission(name, description = nil, &block)
        @group_dsl.permission(name, description, &block)
      end

      def group(key, &block)
        # Pass the group back to the source group.
        @group_dsl.group(key, &block)
      end

      def set(&block)
        @group_dsl.set(&block)
      end

    end
  end
end
