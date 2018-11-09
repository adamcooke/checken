require 'spec_helper'
require 'checken/permission'

describe Checken::Permission do

  subject(:schema) { Checken::Schema.new }
  subject(:group) { schema.root_group }
  subject(:permission) { schema.root_group.add_permission(:change_password) }

  context "#initialize" do
    it "should not be able to created without a group" do
      expect { Checken::Permission.new(nil, :change_password) }.to raise_error Checken::Error
    end
  end

  context "#path" do
    it "should return the path" do
      expect(permission.path).to eq 'change_password'
    end

    it "should include the groups path" do
      another_group = schema.root_group.add_group(:user)
      permission = another_group.add_permission(:change_password)
      expect(permission.path).to eq 'user.change_password'
    end
  end


  context "#add_rule" do
    it "should be able to add a rule" do
      rule = permission.add_rule(:must_belong_to_account) { |user| user == 1234}
      expect(rule).to be_a(Checken::Rule)
    end

    it "should raise an error when a rule already exists on this permission" do
      rule = permission.add_rule(:must_belong_to_account) { |user| user == 1234}
      expect { permission.add_rule(:must_belong_to_account) { |user| user == 1234 } }.to raise_error Checken::Error, /already exists/
    end
  end

  context "#add_context" do
    it "should be able to add a context" do
      permission.add_context(:admin)
      expect(permission.contexts).to include :admin
    end

    it "should return false if a context already exists" do
      expect(permission.add_context(:admin)).to eq :admin
      expect(permission.add_context(:admin)).to be false
    end
  end

  context "#add_dependency" do
    it "should be able to add a dependency" do
      permission.add_dependency("view.thing")
      expect(permission.dependencies).to include "view.thing"
    end

    it "should return false if a dependency already exists" do
      expect(permission.add_dependency("view.thing")).to eq "view.thing"
      expect(permission.add_dependency("view.thing")).to be false
    end
  end

  context "#add_required_object_type" do
    it "should be able to add a required object type" do
      permission.add_required_object_type("Account")
      expect(permission.required_object_types).to include "Account"
    end

    it "should return false if a context already exists" do
      expect(permission.add_required_object_type("Account")).to eq "Account"
      expect(permission.add_required_object_type("Account")).to be false
    end
  end

  context "#parents" do
    it "should include the root group" do
      expect(permission.parents.size).to eq 1
      expect(permission.parents.first.key).to eq nil
    end

    it "should include other groups in order" do
      another_group = schema.root_group.add_group(:user)
      permission = another_group.add_permission(:change_password)
      expect(permission.parents.size).to eq 2
      expect(permission.parents[0].key).to eq nil
      expect(permission.parents[1].key).to eq :user
    end

    it "should include other groups in order" do
      another_group1 = schema.root_group.add_group(:user)
      another_group2 = another_group1.add_group(:subgroup)
      permission = another_group2.add_group(:change_password)
      expect(permission.parents.size).to eq 3
      expect(permission.parents[0].key).to eq nil
      expect(permission.parents[1].key).to eq :user
      expect(permission.parents[2].key).to eq :subgroup
    end

  end

  context "#required_object_types" do
    it "should be settable after initialization" do
      permission = schema.root_group.add_permission(:change_password)
      expect(permission.required_object_types).to be_a Array
      permission.required_object_types << 'FakeUser'
      expect(permission.required_object_types).to include 'FakeUser'
    end
  end

  context "#check!" do
    subject(:user) { FakeUser.new(['change_password']) }

    it "should return true if there are no rules and is granted" do
      permission = schema.root_group.add_permission(:change_password)
      expect(permission.check!(user)).to be true
    end

    it "should return true if all the rules are satisified" do
      permission = schema.root_group.add_permission(:change_password)
      permission.add_rule(:must_be_called_adam) { |user| user.name == "Adam" }
      user.name = "Adam"
      expect(permission.check!(user)).to be true
    end

    it "should raise an error if the user is not granted the permission" do
      permission = schema.root_group.add_permission(:two_factor_auth)
      expect { permission.check!(user) }.to raise_error Checken::PermissionDeniedError do |e|
        expect(e.code).to eq 'PermissionNotGranted'
        expect(e.permission).to eq permission
      end
    end

    it "should raise an error if an invalid object is provided" do
      permission = schema.root_group.add_permission(:change_password)
      permission.required_object_types << 'Array'
      expect { permission.check!(user, Hash.new) }.to raise_error(Checken::InvalidObjectError)
    end

    it "should raise an error if any rule is not satisfied" do
      permission = schema.root_group.add_permission(:change_password)
      rule = permission.add_rule(:must_be_called_adam) { |user| user.name == "Adam" }
      user.name = "Dan"
      expect { permission.check!(user) }.to raise_error Checken::PermissionDeniedError do |e|
        expect(e.code).to eq 'RuleNotSatisifed'
        expect(e.permission).to eq permission
        expect(e.rule).to eq rule
      end
    end

    it "should invoke dependent permissions" do
      permission1 = group.add_permission(:change_password)
      permission2 = group.add_permission(:change_to_insecure_password)
      permission2.dependencies << 'change_password'

      user = FakeUser.new(['change_to_insecure_password'])
      expect { permission1.check!(user) }.to raise_error Checken::PermissionDeniedError
      expect { permission2.check!(user) }.to raise_error Checken::PermissionDeniedError do |e|
        expect(e.code).to eq 'PermissionNotGranted'
        expect(e.permission).to eq permission1
      end
    end

    it "should raise an error if not in the correct context" do
      permission1 = group.add_permission(:change_password)
      permission1.contexts << :admin
      user = FakeUser.new(['change_password'])
      user.checken_contexts << :reseller
      expect { permission1.check!(user) }.to raise_error Checken::PermissionDeniedError do |e|
        expect(e.code).to eq 'NotInContext'
        expect(e.permission).to eq permission1
      end
    end

    it "should be granted in the corrext context" do
      permission1 = group.add_permission(:change_password)
      permission1.contexts << :admin
      user = FakeUser.new(['change_password'])
      user.checken_contexts << :admin
      expect { permission1.check!(user) }.to_not raise_error
    end

    it "should be granted in the corrext context when given an array" do
      permission1 = group.add_permission(:change_password)
      permission1.contexts << :admin
      user = FakeUser.new(['change_password'])
      user.checken_contexts << :reseller
      user.checken_contexts << :admin
      expect { permission1.check!(user) }.to_not raise_error
    end
  end

  context "#first_unsatisifed_rule" do

    subject(:permission) do
      permission = schema.root_group.add_permission(:edit_project)
      permission.required_object_types << 'FakeProject'
      permission.add_rule(:must_be_archived) { |u, o| o.archived? }
      permission
    end

    subject(:user_proxy) { Checken::UserProxy.new(FakeUser.new([permission.path])) }

    it "should return an empty array if all rules are satisifed" do
      fake_project = FakeProject.new('Example', true)
      expect(permission.first_unsatisifed_rule(user_proxy, fake_project)).to be nil
    end

    it "should return the errored rule object" do
      fake_project = FakeProject.new('Example', false)
      rule = permission.first_unsatisifed_rule(user_proxy, fake_project)
      expect(rule).to be_a Checken::Rule
      expect(rule.key).to eq :must_be_archived
    end
  end

end
