require 'spec_helper'
require 'checken/schema'
require 'checken/permission_group'

describe Checken::PermissionGroup do

  subject(:schema) { Checken::Schema.new }

  context "#add_group" do
    it "should be able to add a group" do
      added_group = schema.root_group.add_group(:test1)
      expect(added_group).to be_a(Checken::PermissionGroup)
    end

    it "should not be able to add a group which has been added" do
      added_group = schema.root_group.add_group(:test1)
      expect { schema.root_group.add_group(:test1) }.to raise_error(Checken::Error, /already exists/)
    end
  end

  context "#add_permission" do
    it "should be able to add a permission" do
      added_group = schema.root_group.add_permission(:test1)
      expect(added_group).to be_a(Checken::Permission)
      expect(added_group.path).to eq "test1"
    end

    it "should not be able to add a permission which has been added" do
      added_group = schema.root_group.add_permission(:test1)
      expect { schema.root_group.add_permission(:test1) }.to raise_error(Checken::Error, /already exists/)
    end
  end

  context "#find_permissions_from_path" do
    it "should return a top level permission" do
      permission = schema.root_group.add_permission(:change_password)
      expect(schema.root_group.find_permissions_from_path('change_password').first).to eq permission
    end

    it "should return a permission in a top level group" do
      group = schema.root_group.add_group(:user)
      permission = group.add_permission(:change_password)
      expect(schema.root_group.find_permissions_from_path('user.change_password').first).to eq permission
    end

    it "should return a permission in a second level group" do
      group1 = schema.root_group.add_group(:users)
      group2 = group1.add_group(:manage)
      permission = group2.add_permission(:edit)
      expect(schema.root_group.find_permissions_from_path('users.manage.edit').first).to eq permission
    end

    it "should raise an error if no permission is found" do
      expect { schema.root_group.find_permissions_from_path('some.invalid.permission') }.to raise_error(Checken::PermissionNotFoundError)
    end

    it "should raise an error if a permission is found early in the path" do
      permission = schema.root_group.add_permission(:change_password)
      expect { schema.root_group.find_permissions_from_path('change_password.something') }.to raise_error(Checken::Error, /too early/)
    end

    it "should raise an error if the final return is not a permission" do
      group1 = schema.root_group.add_group(:users)
      group2 = group1.add_group(:manage)
      expect { schema.root_group.find_permissions_from_path('users.manage') }.to raise_error(Checken::Error, /Last part of path was not a permission/)
    end

    it "should raise an error if the given permission is blank or nil" do
      expect { schema.root_group.find_permissions_from_path('') }.to raise_error(Checken::PermissionNotFoundError)
      expect { schema.root_group.find_permissions_from_path(nil) }.to raise_error(Checken::PermissionNotFoundError)
    end

    it "should work with a trailing wildcard" do
      group = schema.root_group.add_group(:users)
      p1 = group.add_permission(:add)
      p2 = group.add_permission(:edit)
      p3 = group.add_permission(:delete)

      found_permissions = schema.root_group.find_permissions_from_path("users.*")
      expect(found_permissions.size).to eq 3
      expect(found_permissions[0]).to eq p1
      expect(found_permissions[1]).to eq p2
      expect(found_permissions[2]).to eq p3
    end

    it "should include all sub group permissions with a double wildcard" do
      group = schema.root_group.add_group(:users)
      p1 = group.add_permission(:add)
      group2 = group.add_group(:subgroup)
      p2 = group2.add_permission(:edit)
      p3 = group2.add_permission(:delete)

      found_permissions = schema.root_group.find_permissions_from_path("users.**.*")
      expect(found_permissions.size).to eq 3
      expect(found_permissions).to include p1
      expect(found_permissions).to include p2
      expect(found_permissions).to include p3
    end
  end

  context "#all_permissions" do
    it "should return all the groups own permissions" do
      permission = schema.root_group.add_permission(:change_password)
      expect(schema.root_group.all_permissions.size).to eq 1
      expect(schema.root_group.all_permissions).to include permission
    end

    it "should return all permissions within any sub groups" do
      group1 = schema.root_group.add_group(:group1)
      p1 = group1.add_permission(:perm1)
      group2 = group1.add_group(:group1)
      p2 = group2.add_permission(:perm2)
      group3 = group2.add_group(:group3)
      p3 = group2.add_permission(:perm3)
      expect(group1.all_permissions.size).to eq 3
      expect(group1.all_permissions).to include p1
      expect(group1.all_permissions).to include p2
      expect(group1.all_permissions).to include p3
    end
  end

  it "should raise an error if a group is created without a key" do
    pg1 = Checken::PermissionGroup.new(schema, nil)
    expect { Checken::PermissionGroup.new(schema, pg1) }.to raise_error(Checken::Error, /without a key/)
  end

  it "should raise an error if a key is given for a root group" do
    expect { Checken::PermissionGroup.new(schema, nil, :test) }.to raise_error(Checken::Error, /with a key/)
  end

end
