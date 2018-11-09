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
        @permission.dependencies << path
      end

      def requires_object(*names)
        names.each do |name|
          @permission.required_object_types << name
        end
      end

    end
  end
end
