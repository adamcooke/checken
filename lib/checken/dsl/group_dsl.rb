require 'checken/dsl/set_dsl'

module Checken
  module DSL
    class GroupDSL

      def initialize(group, options = {})
        @group = group

        if options[:active_sets]
          @active_sets = options[:active_sets]
        end
      end

      def name(name)
        @group.name = name
      end

      def description(description)
        @group.description = description
      end

      def set(&block)
        dsl = SetDSL.new(self)
        active_sets << dsl
        dsl.instance_eval(&block) if block_given?
        dsl
      ensure
        active_sets.pop
      end

      def group(key, &block)
        sub_group = @group.groups[key.to_sym] || @group.add_group(key.to_sym)
        sub_group.dsl(:active_sets => active_sets, &block) if block_given?
        sub_group
      end

      def permission(key, description = nil, &block)
        permission = @group.add_permission(key)
        permission.description = description

        active_sets.each do |set_dsl|
          set_dsl.required_object_types.each do |rot|
            permission.required_object_types << rot
          end

          set_dsl.rules.each do |key, value|
            permission.rules[key] = value
          end

          set_dsl.dependencies.each do |path|
            permission.dependencies << path
          end
        end

        permission.dsl(&block) if block_given?
        permission
      end

      private

      def active_sets
        @active_sets ||= []
      end

    end
  end
end
