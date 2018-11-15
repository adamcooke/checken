require 'spec_helper'
require 'checken/schema'

describe Checken::DSL::GroupDSL do

  subject(:schema) { Checken::Schema.new }

  it "should allow rules to be added" do
    schema.root_group.dsl do
      permission :change_password do
        rule :must_be_adam do
          1 == 1
        end
      end
    end
    expect(schema.root_group[:change_password].rules[:must_be_adam]).to be_a Checken::Rule
  end

  it "should allow dependencies to be added" do
    schema.root_group.dsl do
      permission :change_password do
        depends_on 'login'
      end
    end
    expect(schema.root_group[:change_password].dependencies).to include 'login'
  end


  it "should allow rules to be included" do
    schema.root_group.dsl do
      permission :change_password do
        include_rule :some_rule
      end
    end
    expect(schema.root_group[:change_password].included_rules[:some_rule]).to be_a Checken::IncludedRule
  end

  it "should allow required objects to be added" do
    schema.root_group.dsl do
      permission :edit_project do
        requires_object 'Project'
      end
    end
    expect(schema.root_group[:edit_project].required_object_types).to include 'Project'
  end

  it "should allow contexts to be added in one line or seperately" do
    schema.root_group.dsl do
      permission :edit_project do
        context :admin, :reseller
        context :user
      end
    end
    expect(schema.root_group[:edit_project].contexts).to include :admin
    expect(schema.root_group[:edit_project].contexts).to include :reseller
    expect(schema.root_group[:edit_project].contexts).to include :user
    expect(schema.root_group[:edit_project].contexts).to_not include :potato
  end

  it "should allow contexts to be overriden" do
    schema.root_group.dsl do
      set do
        context :admin
        permission :edit_project do
          context! :user
        end
      end
    end
    expect(schema.root_group[:edit_project].contexts).to include :user
    expect(schema.root_group[:edit_project].contexts).to_not include :admin
  end




end
