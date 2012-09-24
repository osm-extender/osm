# encoding: utf-8
require 'spec_helper'


describe "Flexi Record Field" do

  it "Create from API data" do
    data = {
      "field" => "f_1",
      "name" => "Field Name",
      "width" => "150",
      "editable" => true
    }

    field = Osm::FlexiRecordField.from_api(data)

    field.id.should == 'f_1'
    field.name.should == 'Field Name'
    field.editable.should be_true
    field.valid?.should be_true
  end

end
