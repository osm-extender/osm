# encoding: utf-8
require 'spec_helper'


describe "Register Field" do

  it "Create" do
    data = {
      'name' => 'Human name',
      'field' => 'machine_name',
      'formatter' => 'doneFormatter',
      'width' => '110px',
      'tooltip' => 'Tooltip'
    }

    field = Osm::RegisterField.new(data)

    field.id.should == 'machine_name'
    field.name.should == 'Human name'
    field.tooltip.should == 'Tooltip'
  end

end
