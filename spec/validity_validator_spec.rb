# encoding: utf-8
require 'spec_helper'


class TestItem
  include ActiveAttr::Model
  attribute :validity
  validates_inclusion_of :validity, :in => [true]
end

class TestModel
  include ActiveAttr::Model
  attribute :item
  validates :item, :validity => true
end

describe "validity validator" do

  it "Item is valid" do
    model = TestModel.new(item: TestItem.new(validity: true))
    model.valid?.should == true
    model.errors.count.should == 0
  end

  it "Item is invalid" do
    model = TestModel.new(item: TestItem.new(validity: false))
    model.valid?.should == false
    model.errors.count.should == 2
    model.errors.messages.should == {:item => ['must be valid', 'validity attribute is invalid: is not included in the list']}
  end

end
