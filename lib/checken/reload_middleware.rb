require 'checken/schema'

module Checken
  class ReloadMiddleware

    def initialize(app)
      @app = app
    end

    def call(env)
      # If we need to reload, we shall do that here.
      unless Rails.application.config.cache_classes
        Checken::Schema.instance.reload
      end

      # Call our app as normal
      @app.call(env)
    end

  end
end
