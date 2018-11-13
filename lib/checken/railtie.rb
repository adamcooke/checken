require 'checken/schema'
require 'checken/reload_middleware'

module Checken
  class Railtie < Rails::Railtie

    initializer 'checken.initialize' do |app|
      # Initialize a new schema for the application when it is loaded.
      Checken::Schema.instance = Checken::Schema.new

      # Default configuration
      Checken::Schema.instance.configure do |config|
        # Set the logger to log into a file in the log directory.
        # This can be overriden later if needed.
        config.logger = Logger.new(Rails.root.join('log', 'checken.log'))
      end

      # Load from a directory
      Checken::Schema.instance.load_from_directory(Rails.root.join('permissions'))

      # Add controller options
      ActiveSupport.on_load :action_controller do
        require 'checken/extensions/action_controller'
        include Checken::Extensions::ActionController
      end

      # Insert the middleware
      app.middleware.insert_before(ActionDispatch::Callbacks, Checken::ReloadMiddleware)
    end

  end
end
