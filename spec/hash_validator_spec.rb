# encoding: utf-8
require 'spec_helper'

module HashValidatorSpec

  class KeyTypeTestModel
    include ActiveAttr::Model
    attribute :hash_attr
    validates :hash_attr, :hash => {:key_type => Fixnum}
  end

  class KeyInTestModel
    include ActiveAttr::Model
    attribute :hash_attr
    validates :hash_attr, :hash => {:key_in => [1, 2]}
  end

  class ValueTypeTestModel
    include ActiveAttr::Model
    attribute :hash_attr
    validates :hash_attr, :hash => {:value_type => Fixnum}
  end

  class ValueInTestModel
    include ActiveAttr::Model
    attribute :hash_attr
    validates :hash_attr, :hash => {:value_in => [1, 2]}
  end


  describe "Hash validator" do


    describe "Key type option" do

      it "Has only correct keys" do
        model = KeyTypeTestModel.new(hash_attr: {1=>'1', 2=>'2'})
        model.valid?.should == true
        model.errors.count.should == 0
      end

      it "Has an incorrect key" do
        model = KeyTypeTestModel.new(hash_attr: {1=>'1', 2=>'2', '3'=>'3'})
        model.valid?.should == false
        model.errors.count.should == 1
        model.errors.messages.should == {hash_attr: ['keys must be a Fixnum ("3" is not).']}
      end

      it "Has several incorrect keys" do
        model = KeyTypeTestModel.new(hash_attr: {1=>'1', 2=>'2', '3'=>'3', '4'=>'4'})
        model.valid?.should == false
        model.errors.count.should == 2
        model.errors.messages.should == {hash_attr: ['keys must be a Fixnum ("3" is not).', 'keys must be a Fixnum ("4" is not).']}
      end

    end


    describe "Key in option" do

      it "Has only correct keys" do
        model = KeyInTestModel.new(hash_attr: {1=>'1', 2=>'2'})
        model.valid?.should == true
        model.errors.count.should == 0
      end

      it "Has an incorrect key" do
        model = KeyInTestModel.new(hash_attr: {1=>'1', 2=>'2', 3=>'3'})
        model.valid?.should == false
        model.errors.count.should == 1
        model.errors.messages.should == {hash_attr: ['keys must be in [1, 2] (3 is not).']}
      end

      it "Has several incorrect keys" do
        model = KeyInTestModel.new(hash_attr: {1=>'1', 2=>'2', 3=>'3', 4=>'4'})
        model.valid?.should == false
        model.errors.count.should == 2
        model.errors.messages.should == {hash_attr: ['keys must be in [1, 2] (3 is not).', 'keys must be in [1, 2] (4 is not).']}
      end

    end


    describe "Value type option" do

      it "Has only correct keys" do
        model = ValueTypeTestModel.new(hash_attr: {'1'=>1, '2'=>2})
        model.valid?.should == true
        model.errors.count.should == 0
      end

      it "Has an incorrect key" do
        model = ValueTypeTestModel.new(hash_attr: {'1'=>1, '2'=>2, '3'=>'3'})
        model.valid?.should == false
        model.errors.count.should == 1
        model.errors.messages.should == {hash_attr: ['values must be a Fixnum ("3" for key "3" is not).']}
      end

      it "Has several incorrect keys" do
        model = ValueTypeTestModel.new(hash_attr: {'1'=>1, '2'=>2, '3'=>'3', '4'=>'4'})
        model.valid?.should == false
        model.errors.count.should == 2
        model.errors.messages.should == {hash_attr: ['values must be a Fixnum ("3" for key "3" is not).', 'values must be a Fixnum ("4" for key "4" is not).']}
      end

    end

    describe "Value in option" do

      it "Has only correct keys" do
        model = ValueInTestModel.new(hash_attr: {'1'=>1, '2'=>2})
        model.valid?.should == true
        model.errors.count.should == 0
      end

      it "Has an incorrect key" do
        model = ValueInTestModel.new(hash_attr: {'1'=>1, '2'=>2, '3'=>'3'})
        model.valid?.should == false
        model.errors.count.should == 1
        model.errors.messages.should == {hash_attr: ['values must be in [1, 2] ("3" for key "3" is not).']}
      end

      it "Has several incorrect keys" do
        model = ValueInTestModel.new(hash_attr: {'1'=>1, '2'=>2, '3'=>'3', '4'=>'4'})
        model.valid?.should == false
        model.errors.count.should == 2
        model.errors.messages.should == {hash_attr: ['values must be in [1, 2] ("3" for key "3" is not).', 'values must be in [1, 2] ("4" for key "4" is not).']}
      end

    end


  end

end
