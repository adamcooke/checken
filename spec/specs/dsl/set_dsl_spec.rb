require 'spec_helper'
require 'checken/schema'

describe Checken::DSL::SetDSL do

  subject(:schema) { Checken::Schema.new }

  it "should allow permissions to be added within a set" do
    schema.root_group.dsl do
      set do
        permission :permission1
      end
    end
    expect(schema.root_group[:permission1]).to be_a Checken::Permission
  end

  it "should allow permissions to be added within a set in nested groups" do
    schema.root_group.dsl do
      set do
        permission :permission1
      end
      group :group1 do
        set do
          permission :permission2
        end
      end
    end
    expect(schema.root_group[:permission1]).to be_a Checken::Permission
    expect(schema.root_group[:group1][:permission2]).to be_a Checken::Permission
  end


  it "should allow you to define multiple permissions with the same requirements and rules" do
    schema.root_group.dsl do
      set do
        requires_object 'Project'
        rule(:some_rule) { 1 == 1 }

        permission :permission1
        permission :permission2
      end
    end

    expect(schema.root_group[:permission1]).to be_a Checken::Permission
    expect(schema.root_group[:permission2]).to be_a Checken::Permission
    expect(schema.root_group[:permission1].required_object_types).to_not be_empty
    expect(schema.root_group[:permission1].required_object_types).to eq schema.root_group[:permission2].required_object_types
    expect(schema.root_group[:permission1].rules).to_not be_empty
    expect(schema.root_group[:permission1].rules).to eq schema.root_group[:permission2].rules
  end

  it "should allow groups to be added within sets" do
    schema.root_group.dsl do
      set do
        rule(:must_be_a_cat) { |u| u.is_a_cat? }

        group :group1 do
          permission :permission1
        end
        group :group2 do
          permission :permission2
        end
      end
    end
    expect(schema.root_group[:group1]).to be_a Checken::PermissionGroup
    expect(schema.root_group[:group2]).to be_a Checken::PermissionGroup
    expect(schema.root_group[:group1][:permission1]).to be_a Checken::Permission
    expect(schema.root_group[:group2][:permission2]).to be_a Checken::Permission
    expect(schema.root_group[:group1][:permission1].rules[:must_be_a_cat]).to be_a Checken::Rule
    expect(schema.root_group[:group2][:permission2].rules[:must_be_a_cat]).to be_a Checken::Rule
    expect(schema.root_group[:group1][:permission1].rules[:must_be_a_cat]).to eq schema.root_group[:group2][:permission2].rules[:must_be_a_cat]
  end

  it "should pass dependencies down to permissions in sub groups" do
    schema.root_group.dsl do
      permission :view
      set do
        depends_on 'view'
        permission :edit

        group :delete do
          permission :any
          permission :archived
          set do
            depends_on 'view.edit'
            permission :active
          end
        end
      end
    end
    expect(schema.root_group[:edit].dependencies).to include 'view'
    expect(schema.root_group[:delete][:any].dependencies).to include 'view'
    expect(schema.root_group[:delete][:active].dependencies).to include 'view'
    expect(schema.root_group[:delete][:active].dependencies).to include 'view.edit'
  end

  it "should make sure permissions within sets have descriptions" do
    schema.root_group.dsl do
      set do
        permission :view, "View something"
      end
    end
    expect(schema.root_group[:view].description).to eq 'View something'
  end

end
