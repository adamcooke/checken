require 'spec_helper'
require 'checken/concerns/has_parents'

describe Checken::Concerns::HasParents do

  subject(:schema) { Checken::Schema.new }

  context "#path" do
    it "should have a nil path a group without a key" do
      expect(schema.root_group.path).to be_nil
    end

    it "should return the key as a string" do
      pg = schema.root_group.add_group(:test)
      expect(pg.path).to eq "test"
    end

    it "should return the key as a string" do
      pg1 = schema.root_group.add_group(:test1)
      pg2 = pg1.add_group(:test2)
      expect(pg2.path).to eq "test1.test2"
    end
  end

  context "#parents" do
    it "should be empty for the root group" do
      expect(schema.root_group.parents).to be_empty
    end

    it "should contain all parents in order" do
      pg1 = schema.root_group.add_group(:test1)
      pg2 = pg1.add_group(:test2)
      expect(pg2.parents[0]).to eq schema.root_group
      expect(pg2.parents[1]).to eq pg1
    end

    it "should not include itself" do
      pg1 = schema.root_group.add_group(:test1)
      expect(pg1.parents).to include(schema.root_group)
      expect(pg1.parents).to_not include(pg1)
    end
  end

  context "#root" do
    it "should return itself for the root group" do
      expect(schema.root_group.root).to eq schema.root_group
    end

    it "should return its parent if it's a first level group" do
      pg1 = schema.root_group.add_group(:test1)
      expect(pg1.root).to eq schema.root_group
    end

    it "should return its parent's parent if it's a second level group" do
      pg1 = schema.root_group.add_group(:test1)
      pg2 = pg1.add_group(:test2)
      expect(pg2.root).to eq schema.root_group
    end
  end

end
