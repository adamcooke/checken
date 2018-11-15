module Checken
  class Error < StandardError
  end

  class PermissionNotFoundError < Error
  end

  class InvalidObjectError < Error
  end

  class NoPermissionsFoundError < Error
  end

  class SchemaError < Error
  end

  class PermissionDeniedError < Error
    attr_reader :code
    attr_reader :description
    attr_reader :permission
    attr_accessor :rule
    attr_accessor :user
    attr_accessor :object

    def initialize(code, description, permission = nil)
      @code = code
      @description = description
      @permission = permission
      @memo = {}
    end

    def message
      "Access denied: #{description} (#{code})"
    end
  end
end
