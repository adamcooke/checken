require 'spec_helper'
require 'checken/schema'

describe Checken::Schema do

  subject(:schema) { Checken::Schema.new }

  context "#check_permission!" do
    it "should not raise an error when granted" do
      permission = schema.root_group.add_permission(:change_password)
      fake_user = FakeUser.new(['change_password'])
      expect { schema.check_permission!('change_password', fake_user) }.to_not raise_error
    end

    it "should not raise an error when context matches" do
      permission = schema.root_group.add_permission(:change_password)
      permission.contexts << :admin
      fake_user = FakeUser.new(['change_password'])
      fake_user.checken_contexts << :admin
      expect { schema.check_permission!('change_password', fake_user, nil) }.to_not raise_error
    end

    it "should raise an error if not granted" do
      permission = schema.root_group.add_permission(:change_password)
      fake_user = FakeUser.new(['logout'])
      expect { schema.check_permission!('change_password', fake_user) }.to raise_error Checken::PermissionDeniedError do |e|
        expect(e.code).to eq 'PermissionNotGranted'
      end
    end

    it "should raise an error if the object provided is not valid" do
      fake_user = FakeUser.new(['add_project'])
      permission = schema.root_group.add_permission(:add_project)
      permission.required_object_types << 'FakeUser'
      expect { schema.check_permission!('add_project', fake_user) }.to raise_error Checken::InvalidObjectError
      expect { schema.check_permission!('add_project', fake_user, Object.new) }.to raise_error Checken::InvalidObjectError
      expect { schema.check_permission!('add_project', fake_user, fake_user) }.to_not raise_error
    end
  end

  context "#check_permission! with wildcards" do

    before(:each) do
      @group1 = schema.root_group.add_group(:projects)
      @group2 = @group1.add_group(:delete)
      @p1 = @group2.add_permission(:any)
      @p1.required_object_types << 'FakeProject'
      @p2 = @group2.add_permission(:only_archived)
      @p2.required_object_types << 'FakeProject'
      @p2.add_rule(:archived_projects_only) { |user, project| project.archived? }
    end

    it "should be be denied if the user has none of the permissions required" do
      fake_user = FakeUser.new(['projects.show'])
      fake_project = FakeProject.new("Example", true)
      expect { schema.check_permission!("projects.delete.*", fake_user, fake_project) }.to raise_error Checken::PermissionDeniedError
    end

    it "should be be denied if any of the rules on granted permissions is not satisified" do
      fake_user = FakeUser.new(['projects.delete.only_archived'])
      fake_project = FakeProject.new("Example", false)
      expect { schema.check_permission!("projects.delete.*", fake_user, fake_project) }.to raise_error Checken::PermissionDeniedError do  |e|
        expect(e.code).to eq 'RuleNotSatisifed'
      end
    end

    it "should be be granted if all rules are satisified on all granted permissions" do
      fake_user = FakeUser.new(['projects.delete.only_archived'])
      fake_project = FakeProject.new("Example", true)
      expect { schema.check_permission!("projects.delete.*", fake_user, fake_project) }.to_not raise_error

      fake_user = FakeUser.new(['projects.delete.any'])
      fake_project = FakeProject.new("Example", false)
      expect { schema.check_permission!("projects.delete.*", fake_user, fake_project) }.to_not raise_error
    end

    it "should be denied if ANY of the rules on matched rules is not satisified" do
      fake_user = FakeUser.new(['projects.delete.any', 'projects.delete.only_archived'])
      fake_project = FakeProject.new("Example", false)
      expect { schema.check_permission!("projects.delete.*", fake_user, fake_project) }.to raise_error Checken::PermissionDeniedError do  |e|
        expect(e.code).to eq 'RuleNotSatisifed'
      end
    end

    it "should raise an error if no permissions are found" do
      fake_user = FakeUser.new([])
      @group1.add_group(:edit)
      expect { schema.check_permission!("projects.edit.*", fake_user) }.to raise_error Checken::NoPermissionsFoundError
    end
  end

  context "#load_from_directory" do
    subject(:fixture_path) { File.join(TEST_ROOT, 'fixtures', 'permissions') }
    it "should return false if the directory doesn't exist" do
      path = File.expand_path("../___doesnt-exist___", __FILE__)
      expect(schema.load_from_directory(path)).to be false
    end

    it "should raise an error if the path is not a directory" do
      expect { schema.load_from_directory(__FILE__) }.to raise_error Checken::Error, /not a directory/
    end

    it "should not raise an error if loaded successfully" do
      expect { schema.load_from_directory(fixture_path) }.to_not raise_error
    end

    it "should load onto the root group DSL" do
      expect { schema.load_from_directory(fixture_path) }.to_not raise_error
      expect(schema.root_group[:change_password]).to be_a Checken::Permission
      expect(schema.root_group[:project][:edit]).to be_a Checken::Permission
      expect(schema.root_group[:project][:edit].dependencies).to include 'project.view'
    end
  end

end
