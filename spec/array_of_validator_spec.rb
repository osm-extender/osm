# encoding: utf-8
require 'spec_helper'


class FixnumTestModel < Osm::Model
  attribute :array
  validates :array, :array_of => {:item_type => Fixnum}
end

class TestItem
  def initialize(attrs)
    @valid = !!attrs[:valid]
  end
  def valid?
    @valid
  end
end

class ValidTestModel < Osm::Model
  attribute :array
  validates :array, :array_of => {:item_type => TestItem, :item_valid=>true}
end

class InvalidTestModel < Osm::Model
  attribute :array
  validates :array, :array_of => {:item_type => TestItem, :item_valid=>false}
end

class NovalidTestModel < Osm::Model
  attribute :array
  validates :array, :array_of => {:item_type => TestItem}
end


describe "Array of validator" do

  it "Allows an empty array" do
    i = FixnumTestModel.new(array: [])
    i.valid?.should == true
    i.errors.count.should == 0
  end

  describe ":item_type option" do

    it "Allows arrays of the right type" do
      i = FixnumTestModel.new(array: [1, 2, 3])
      i.valid?.should == true
      i.errors.count.should == 0
    end

    it "Forbids arrays containing >= 1 incorrect type" do
      i = FixnumTestModel.new(array: [1, '2', 3])
      i.valid?.should == false
      i.errors.count.should == 1
      i.errors.messages.should == {:array=>["items in the Array must be a Fixnum"]}
    end

  end

  describe ":valid option" do

    it "Allows (in)valid items unless valid option is passed" do
      i = NovalidTestModel.new(array: [TestItem.new(valid: false), TestItem.new(valid: true)])
      i.valid?.should == true
      i.errors.count.should == 0
    end

    describe "Valid option is false" do

      it "Contains all invalid items" do
        i = InvalidTestModel.new(array: [TestItem.new(valid: false)])
        i.valid?.should == true
        i.errors.count.should == 0
      end

      it "Contains a valid item" do
        i = InvalidTestModel.new(array: [TestItem.new(valid: true)])
        i.valid?.should == false
        i.errors.count.should == 1
        i.errors.messages.should == {:array => ['contains a valid item']}
      end

    end

    describe "Valid option is true" do

      it "Contains all valid items" do
        i = ValidTestModel.new(array: [TestItem.new(valid: true)])
        i.valid?.should == true
        i.errors.count.should == 0
      end

      it "Contains an invalid item" do
        i = ValidTestModel.new(array: [TestItem.new(valid: false)])
        i.valid?.should == false
        i.errors.count.should == 1
        i.errors.messages.should == {:array => ['contains an invalid item']}      end
    end

  end

end
