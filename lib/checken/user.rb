module Checken
  module User

    # Can the user perform the given action?
    #
    # @param permission_path [String] the permission name/path
    # @option options [Checken::Schema] :schema an optional scheme to use
    # @return [Boolean]
    def can?(permission_path, object_or_options = {}, options_when_object_provided = {})

      if object_or_options.is_a?(Hash)
        object = nil
        options = object_or_options
      else
        object = object_or_options
        options = options_when_object_provided
      end

      schema = options.delete(:schema) || Checken.current_schema || Checken::Schema.instance

      if schema.nil?
        raise Error, "Could not determine a schema. Make sure you set Checken.current_schema or pass :schema to can? methods."
      end

      user_proxy = schema.config.user_proxy_class.new(self)
      schema.check_permission!(permission_path, user_proxy, object)
      true
    rescue Checken::PermissionDeniedError => e
      false
    end

  end
end
