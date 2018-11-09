module Checken
  # The user proxy class sits on top of a user and provides the methods that
  # checken needs. You can write your own proxy or use the default. If you use
  # the default you'll need to make sure that the users you provide implement
  # the methods this proxy will call.
  #
  # All interactions between checken and a user will happen via a proxy. This
  # default class is a useful benchmark list of how your user should behave.
  class UserProxy

    attr_accessor :user

    # @param user [Object]
    def initialize(user)
      @user = user
    end

    # Return a suitable description for this user for use in log files
    #
    # @return [String]
    def description
      if @user.respond_to?(:id)
        "#{@user.class}##{@user.id}"
      else
        "#{@user.class}"
      end
    end

    # Returns an array of permissions that this user has permission to
    # use.
    #
    # @return [Array<String>]
    def granted_permissions
      @user.assigned_checken_permissions
    end

    # An array of contexts that this user is part of
    #
    # @return [Array<Symbol>]
    def contexts
      if @user.respond_to?(:checken_contexts)
        @user.checken_contexts
      else
        []
      end
    end

  end
end
