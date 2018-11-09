require 'spec_helper'

describe Checken::User do

  subject(:schema) do
    schema = Checken::Schema.new
    schema.root_group.add_permission('change_password')
    schema
  end
  before(:each) { Checken.current_schema = schema }
  after(:each) { Checken.current_schema = nil }

  context "#can?" do
    it "should return true when permission is granted" do
      user = FakeUser.new(['change_password'])
      expect(user.can?('change_password')).to be true
    end

    it "should return false when permission is denied" do
      user = FakeUser.new(['other'])
      expect(user.can?('change_password')).to be false
    end

    it "should allow a schema to be provided as an option" do
      other_schema = Checken::Schema.new
      other_schema.root_group.add_permission 'logout'
      user = FakeUser.new(['logout'])
      expect(user.can?('logout', :schema => other_schema)).to be true
    end
  end
end
