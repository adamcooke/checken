module Checken
  module Extensions
    module ActionController

      def self.included(base)
        base.extend ClassMethods
        base.helper_method :granted_checken_permissions
      end

      def restrict(permission_path, object = nil, options = {})
        user = send(Checken.current_schema.config.current_user_method_name)
        granted_permissions = Checken.current_schema.check_permission!(permission_path, user, object)
        granted_permissions.each do |permission|
          granted_checken_permissions << permission
        end
      end

      def granted_checken_permissions
        @granted_checken_permissions ||= []
      end

      module ClassMethods
        def restrict(permission_path, object_or_options = {}, options_if_object_provided = {})
          if object_or_options.is_a?(Hash)
            object = nil
            options = object_or_options
          else
            object = object_or_options
            options = options_if_object_provided
          end

          restrict_options = options.delete(:restrict_options)

          before_action(options) do
            if object.is_a?(Proc)
              # If a proc is given, resolve manually
              resolved_object = object.call
            elsif object.is_a?(Symbol)
              if object.to_s =~ /\A@/
                resolved_object = instance_variable_get(object.to_s)
              else
                resolved_object = send(object)
              end
            else
              # Otherwise, the object is nil
              resolved_object = nil
            end

            restrict(permission_path, resolved_object, restrict_options)
          end

        end
      end

    end
  end
end
