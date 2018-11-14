require 'checken/schema'

module Checken
  class ReloadMiddleware

    MUTEX = Mutex.new

    def initialize(app)
      @app = app
    end

    def call(env)
      # If we need to reload, we shall do that here.
      unless Rails.application.config.cache_classes
        MUTEX.synchronize do
          Checken::Schema.instance.reload
        end
      end

      # Call our app as normal
      @app.call(env)
    end

  end
end
