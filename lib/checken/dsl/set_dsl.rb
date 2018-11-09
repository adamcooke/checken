module Checken
  module DSL
    class SetDSL

      attr_reader :rules
      attr_reader :required_object_types
      attr_reader :dependencies

      def initialize(group_dsl)
        @group_dsl = group_dsl
        @rules = {}
        @required_object_types = []
        @dependencies = []
      end

      def rule(name, &block)
        @rules[name] = Rule.new(name, &block)
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
