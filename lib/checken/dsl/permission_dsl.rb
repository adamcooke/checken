module Checken
  module DSL
    class PermissionDSL

      def initialize(permission)
        @permission = permission
      end

      def rule(key, &block)
        @permission.add_rule(key, &block)
      end

      def depends_on(path)
        @permission.add_dependency(path)
      end

      def include_rule(key, options = {}, &block)
        @permission.include_rule(key, options, &block)
      end

      def requires_object(*names)
        names.each do |name|
          @permission.add_required_object_type(name)
        end
      end

      def context(*contexts)
        contexts.each do |context|
          @permission.add_context(context)
        end
      end

      def context!(*contexts)
        @permission.remove_all_contexts
        context(*contexts)
      end

    end
  end
end
