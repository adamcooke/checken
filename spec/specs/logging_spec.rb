require 'spec_helper'
require 'checken/schema'

class TestLogger
  attr_accessor :messages
  def initialize
    @messages = []
  end

  def info(message)
    @messages << message
  end
end
describe "Logging" do
  subject(:logger) { TestLogger.new }
  subject(:schema) do
    schema = Checken::Schema.new
    schema.config.logger = logger
    schema
  end

  it "should log successes" do
    schema.root_group.add_permission(:change_password)
    schema.check_permission!("change_password", FakeUser.new(['change_password']))
    expect(logger.messages).to include "`change_password` granted to FakeUser"
  end

  it "should log when the permission is not granted" do
    schema.root_group.add_permission(:change_password)
    expect { schema.check_permission!("change_password", FakeUser.new([])) }.to raise_error Checken::PermissionDeniedError
    expect(logger.messages).to include "`change_password` not granted to FakeUser"
  end

  it "should log when the permission fails a rule check" do
    permission = schema.root_group.add_permission(:change_password)
    permission.add_rule(:must_be_something) { false }
    expect { schema.check_permission!("change_password", FakeUser.new(['change_password'])) }.to raise_error Checken::PermissionDeniedError
    expect(logger.messages).to include "`change_password not granted to FakeUser because rule `must_be_something` on `change_password` was not satisified."
  end
end
