require 'checken/version'
require 'checken/user'

module Checken

  # Return the current global scheme
  def self.current_schema
    Thread.current[:cheken_schema] || Checken::Schema.instance
  end

  # Set the current global schema
  def self.current_schema=(schema)
    Thread.current[:cheken_schema] = schema
  end

end

if defined?(Rails)
  require 'checken/railtie'
end
