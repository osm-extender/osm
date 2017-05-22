# encoding: utf-8
require 'spec_helper'

module ValidityValidatorSpec
  class TestItem
    include ActiveAttr::Model
    attribute :validity
    validates_inclusion_of :validity, in: [true]
  end

  class TestModel
    include ActiveAttr::Model
    attribute :item
    validates :item, validity: true
  end
  class TestModelAllowNil
    include ActiveAttr::Model
    attribute :item
    validates :item, validity: {allow_nil: true}
  end
  class TestModelDisallowNil
    include ActiveAttr::Model
    attribute :item
    validates :item, validity: {allow_nil: false}
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
      model.errors.messages.should == {item: ['must be valid', 'validity attribute is invalid: is not included in the list']}
    end

    describe "Allow nil" do

      it "Is true" do
        TestModelAllowNil.new(item: TestItem.new(validity: true)).valid?.should == true
        TestModelAllowNil.new(item: TestItem.new(validity: false)).valid?.should == false
        TestModelAllowNil.new(item: nil).valid?.should == true
      end

      it "Is false" do
        TestModelDisallowNil.new(item: TestItem.new(validity: true)).valid?.should == true
        TestModelDisallowNil.new(item: TestItem.new(validity: false)).valid?.should == false
        TestModelDisallowNil.new(item: nil).valid?.should == false
      end

    end

  end

end
