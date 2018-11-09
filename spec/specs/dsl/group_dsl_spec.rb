require 'spec_helper'
require 'checken/schema'

describe Checken::DSL::GroupDSL do

  subject(:schema) { Checken::Schema.new }

  it "should allow sub groups to be added" do
    schema.root_group.dsl do
      group :test1 do
        group :test2
      end
    end
    expect(schema.root_group[:test1]).to be_a Checken::PermissionGroup
    expect(schema.root_group[:test1].path).to eq "test1"
    expect(schema.root_group[:test1][:test2]).to be_a Checken::PermissionGroup
    expect(schema.root_group[:test1][:test2].path).to eq "test1.test2"
  end

  it "should allow permissions to be added" do
    schema.root_group.dsl do
      permission :change_password
    end
    expect(schema.root_group[:change_password]).to be_a Checken::Permission
  end

  it "should allow permissions to be added with a description" do
    schema.root_group.dsl do
      permission :change_password, "Can change password"
    end
    expect(schema.root_group[:change_password]).to be_a Checken::Permission
    expect(schema.root_group[:change_password].description).to eq "Can change password"
  end

  it "should be able set dependencies to all permissions within a group" do
    schema.root_group.dsl do
      permission :view, "Can view thing"
      group :edit do
        set do
          depends_on "view"
          permission :any, "Can edit any details"
          permission :archived, "Can edit archived things"
          set do
            depends_on "view.any"
            permission :something, "Can do something"
          end
          permission :something_else, "Can do something else"
        end
      end
      permission :delete, "Can delete"
    end

    expect(schema.root_group[:edit][:any].dependencies).to include("view")
    expect(schema.root_group[:edit][:archived].dependencies).to include("view")
    expect(schema.root_group[:edit][:something].dependencies).to include("view")
    expect(schema.root_group[:edit][:something].dependencies).to include("view.any")
    expect(schema.root_group[:edit][:something_else].dependencies).to include("view")
    expect(schema.root_group[:edit][:something_else].dependencies).to_not include("view.any")
    expect(schema.root_group[:delete].dependencies).to be_empty
  end

  it "should reopen groups if they already have been defined" do
    schema.root_group.dsl do
      group :projects do
        permission :list
        group :edit do
          permission :details
        end
      end
      group :projects do
        permission :view
        group :edit do
          permission :icon
        end
      end
    end
    expect(schema.root_group[:projects][:list]).to be_a Checken::Permission
    expect(schema.root_group[:projects][:view]).to be_a Checken::Permission
    expect(schema.root_group[:projects][:edit][:details]).to be_a Checken::Permission
    expect(schema.root_group[:projects][:edit][:icon]).to be_a Checken::Permission
  end

end
