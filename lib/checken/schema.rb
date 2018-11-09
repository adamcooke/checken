require 'checken/config'
require 'checken/permission'
require 'checken/permission_group'

module Checken
  class Schema

    class << self
      # This can be used for storing a global instance of a schema for an application
      # that may require such a thing.
      attr_accessor :instance
    end

    attr_reader :root_group
    attr_reader :config

    # Create a new schema
    #
    def initialize
      @root_group = PermissionGroup.new(self, nil)
      @config = Config.new
    end

    # Add configuration for this schema
    def configure(&block)
      block.call(@config)
    end

    # Does the given user have the appropriate permissions to handle?
    #
    # @param permission_path [String]
    # @param user [User]
    # @param object [Object]
    def check_permission!(permission_path, user_proxy, object = nil)
      permissions = @root_group.find_permissions_from_path(permission_path)

      if permissions.size == 1
        # If we only have a single permission, we'll just run the check
        # as normal through the check process. This will work as normal and raise
        # and return directly.
        permissions.first.check!(user_proxy, object)

      elsif permissions.size == 0
        # No permissions found
        raise Checken::NoPermissionsFoundError, "No permissions found matching #{permission_path}"

      else
        # If we have multiple permissions, we need to loop through each permission
        # and handle them as appropriate.
        ungranted_permissions = 0
        permissions.each do |permission|
          begin
            permission.check!(user_proxy, object)
          rescue Checken::PermissionDeniedError => e
            if e.code == 'PermissionNotGranted'
              # If the permission isn't granted, update the counter so we can
              # keep track of the number of ungranted permissions.
              ungranted_permissions += 1
            else
              # Raise other errors as normal
              raise
            end
          end
        end

        if permissions.size == ungranted_permissions
          # If the user is ungranted to all the found permissions, they do not
          # have access and should be denied.
          raise PermissionDeniedError.new('PermissionNotGranted', "User does not have any permissions #{permissions.map(&:path).join(', ')} permission.", permissions.first)
        else
          true
        end
      end
    end

    # Load a set of schema files from a given directory
    #
    # @param path [String]
    # @return [Boolean]
    def load_from_directory(path)
      # Store the load path for future reload
      @load_path = path

      # If the path doesn't exist, just return false. We won't load anything
      # if the directory hasnt' been loaded yet.
      unless File.exist?(path)
        return false
      end

      # Check that the directory is a a directory
      unless File.directory?(path)
        raise Error, "Path to directory must be a directory. #{path} is not a directory."
      end

      # Read all the files and pass them through the DSL for the root schema.
      # Each directory is a group. Everything in the root will be at the root.
      Dir[File.join(path, "**", "*.rb")].each do |path|
        contents = File.read(path)
        dsl = DSL::GroupDSL.new(@root_group)
        dsl.instance_eval(contents, path)
      end

      logger.info "Loaded permission schema from #{path}"

      true
    end

    # Reload the schema from the directory if possible
    #
    # @return [void]
    def reload
      if @load_path
        @root_group = PermissionGroup.new(self, nil)
        load_from_directory(@load_path)
        true
      else
        raise Error, "Cannot reload a schema that wasn't loaded from a directory"
      end
    end

    # Return the logger
    #
    # @return [Logger]
    def logger
      @config.logger
    end

  end
end
