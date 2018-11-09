module Checken
  module Concerns
    module HasParents

      # Return the full path to this permission
      #
      # @return [String]
      def path
        @key.nil? ? nil : [@group.path, @key].compact.join('.')
      end

      # Return the parents for ths group
      #
      # @return [Array<Checken::PermissionGroup, Checken::Permission>]
      def parents
        @key.nil? ? [] : [@group.parents, @group].compact.flatten
      end

      # Return the root group
      #
      # @return [Checken::PermissionGroup]
      def root
        @key.nil? ? self : parents.first
      end

    end
  end
end
