# Start with some simple global permissions
permission :change_password, 'Change password'
permission :global_search, 'Use global search'

# Make a group that applies to a collection of projects
group :projects do
  permission :list, "List all projects"
  permission :create, "Create projects" do
    rule :must_have_credits do |user|
      user.available_projects > 0
    end
  end
end

# Make a group that applies to member projects and requires that
# the permissions are passed a project.
group :project do
  permission :view, "View a project" do
    requires_object 'Project'
    rule :must_own_project do |user, project|
      project.user == user
    end
  end

  set do
    depends_on 'project.view'

    permission :edit, "Edit a project"
    permission :delete, "Delete a project"
  end
end
