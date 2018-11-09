# Checken 🐔

Checken is an authorization framework for Ruby/Rails applications to allow you to build a complete permission & access control system for your users. The goals of the project are:

* To allow you easily to verify whether a user is permitted to perform an action.
* Support any number of different actions.
* Allow actions to be associated with an object.

This is an example of the DSL required to get started:

```ruby
# At its most basic, you can define a simple permission
permission :change_password, 'Change own password'

# and then check whether a user has a permission
current_user.can?(:change_password)

# or raise an error if the user does not have the permission
current_user.can!(:change_password) # => Chickit::AccessDenied
```

Things can, however, get more complicated when you want to start checking whether a user has access to view or make changes to a specific resource. In this example, we're going to look at using groups and rules to determine.

```ruby
group :projects do
  # If the user has the permission AND the rule is satisife this permission will be granted. If either fail, the permission will be denied.
  permission :list, 'List projects' do
    rule(:must_be_active) { |user| user.active? }
  end

  # You can also use an object
  permission :show, 'View project information' do
    requires_object 'Project'
    rule(:must_belong_to_projects_account) { |user, project| user.account == project.account }
  end
end

# We can use this in an action or view to determine if a user can perform an action.
# We pass the objects required by the permission as arguments.
current_user.can?('projects.list', current_account)

# We can also use this project an action at the controller class level. The
# second argument is, optionally, the object to provide. A symbol will be called
# as a method or you can provide a proc. The user must be available as
# current_user.
restrict 'projects.list', :current_account, only: [:index]
restrict 'projects.list', proc { current_account }, only: [:index]
```

This works well for browsing projects, but we may also want to restrict access to perform actions within a resource based on the state of the resource and/or user.

```ruby
group :projects do
  group :delete do
    requires_object 'Project' do
      permission :any, 'Can delete any projects'
      permission :archived_only, 'Can only delete archived projects' do
        rule(:must_be_archived) { |user, project| project.archived? }
      end

      rule(:must_belong_to_projects_account) { |user, project| user.account == project.account }
    end
  end
end

# Using a wildcard in the permission will allow allow any permission role through
# but will check that all rules for all assigned permissions are satisifed before
# allowing the request through.
current_user.can?('projects.delete.*', @project)
```

Next up, you might need to add dependencies to avoid needing further complexity to your ruleset.

```ruby
group :projects do
  permission :view, 'Can view a project', 'Project' do
    rule('ProjectMustBelongToUsersAccount') { |user, project| user.account == project.account }
  end

  permission :edit, 'Can edit a project', 'Project' do
    depends_on "projects.view"
    rule("MustBeAnAdminUser") { |user, project| user.admin? }
  end
end

# In this case you can use a single can statement which will check that the user
# satisifes all dependent rules as well as itself before granting permission.
current_user.can?('projects.edit', @project)
```

Dependencies can also be added at a group level to apply the dependency to all permissions within this group and all subsequent groups.

```ruby
group :projects do
  group :update do
    depends_on 'projects.view'

    # [...] Additional permissions in here which will all depend on the
    #       projects.view permission.
  end
end
```

You may also wish to handle restrictions based on changes made to an model's attributes. This can be achieved as follows. In this example, we only wish to allow certain users to change a project's price plan.

```ruby
group :projects do
  permission :change_price_plan, "Can change a project's price plan", 'Project'
end

# Once you've got the permission in place, you need to tell the model about it
# and how it works.
class Project < ApplicationRecord
  # Add the restriction to your model. This specifies which permission is required
  # to change certain attributes.
  restrict 'projects.change_price_plan', :on => :update, :attributes => [:price_plan_id]
end

# You'll need to make ActiveRecord aware of the user that is performing an action
# before you invoke any save/destroy requests. If there is no user provided, these
# check will NOT be invoked (you have been warned!).
project = Project.find(1)
project.current_user = current_user
project.price_plan = params[:price_plan_id]
project.save!

# You can define it globally in the Thread if you'd prefer. This will automatically
# store the current user in a thread local variable and remove it after each request.
# You can do this automatically if you prefer.
around_action :add_current_user_to_check
# or do it manually...
around_action do
  begin
    Check.current_user = current_user
    yield
  ensure
    Check.current_user = nil
  end
end
```

All permission checks are logged into a file by default. You can log these into a database if you'd prefer. By default, these logs are stored in log/chick.log and are rotated automatically. You can adjust these options in the settings.

Chick will failsafe so if there's any doubt about how to handle a permission check, it will be denied.
