require 'checken/permission'
require 'checken/error'
require 'checken/concerns/has_parents'
require 'checken/dsl/group_dsl'

module Checken
  class PermissionGroup

    include Checken::Concerns::HasParents

    attr_accessor :name
    attr_accessor :description
    attr_reader :schema
    attr_reader :group
    attr_reader :key
    attr_reader :groups
    attr_reader :permissions

    # Return a group or permission matching the given key
    #
    # @param group_or_permission_key [Symbol]
    # @return [Checken::PermissionGroup, Checken::Permission, nil]
    def [](group_or_permission_key)
      @groups[group_or_permission_key.to_sym] || @permissions[group_or_permission_key.to_sym]
    end

    # Create a new permission group
    #
    # @param group [Checken::PermissionGroup, nil]
    # @param key [Symbol]
    def initialize(schema, group, key = nil)
      if group && key.nil?
        raise Error, "Cannot create a new non-root permission group without a key"
      elsif group.nil? && key
        raise Error, "Cannot create a new root permission group with a key"
      end

      @schema = schema
      @group = group
      @key = key.to_sym if key
      @groups = {}
      @permissions = {}
    end

    # Return a group or a permission that matches the given key
    #
    # @return [Cheken::PermissionGroup, Checken::Permission]
    def group_or_permission(key)
      key = key.to_sym
      @groups[key] || @permissions[key]
    end

    # Adds a new sub group to this group
    #
    # @param key [String]
    # @return [Checken::PermissionGroup]
    def add_group(key)
      key = key.to_sym
      if group_or_permission(key).nil?
        @groups[key] = PermissionGroup.new(@schema, self, key)
      else
        raise Error, "Group or permission with key of #{key} already exists"
      end
    end

    # Adds a permission to the group
    #
    # @param key [String]
    # @return [Checken::Permission]
    def add_permission(key)
      key = key.to_sym
      if group_or_permission(key).nil?
        @permissions[key] = Permission.new(self, key)
      else
        raise Error, "Group or permission with key of #{key} already exists"
      end
    end

    # Find permissions from a path
    def find_permissions_from_path(path)
      unless path.is_a?(String) && path.length > 0
        raise PermissionNotFoundError, "Must provide a permission path"
      end

      path_parts = path.split('.').map(&:to_sym)
      last_group_or_permission = self
      while part = path_parts.shift
        if part == :*
          if path_parts.empty?
            # We're at the end of the path, that's an acceptable place for a wildcard.
            # Return all the permissions in the final group.
            return last_group_or_permission.permissions.values
          else
            raise Error, "Wildcards must be placed at the end of a permission path"
          end
        else
          last_group_or_permission = last_group_or_permission.group_or_permission(part)
          if last_group_or_permission.is_a?(Permission) && !path_parts.empty?
            raise Error, "Permission found too early in the path. Permission key should always be at the end of the path."
          elsif last_group_or_permission.nil?
            raise PermissionNotFoundError, "No permission found matching '#{path}'"
          end
        end
      end

      if last_group_or_permission.is_a?(Permission)
        [last_group_or_permission]
      else
        raise Error, "Last part of path was not a permission. Last part of permission must be a path"
      end
    end

    # Execute the given block within the group DSL
    #
    # @return [Checken::DSL::GroupDSL]
    def dsl(options = {}, &block)
      dsl = DSL::GroupDSL.new(self, options)
      dsl.instance_eval(&block)
      dsl
    end

  end
end
