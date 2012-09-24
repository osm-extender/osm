# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Flexi Record Data" do

  it "Create from API data" do
    data = {
      "scoutid" => "1",
      "firstname" => "First",
      "lastname" => "Last",
      "dob" => "1899-11-30",
      "patrolid" => "2",
      "total" => "3",
      "completed" => "",
      "f_1" => "a",
      "f_2" => "b",
      "age" => "",
      "patrol" => "Green"
    }

    rd = Osm::FlexiRecordData.from_api(data)

    rd.member_id.should == 1
    rd.grouping_id.should == 2
    rd.first_name.should == 'First'
    rd.last_name.should == 'Last'
    rd.total.should == 3
    rd.completed.nil?.should be_true
    rd.age.nil?.should be_true
    rd.date_of_birth.should == Date.new(1899, 11, 30)
    rd.fields.should == {
      'f_1' => 'a',
      'f_2' => 'b',
    }
    rd.valid?.should be_true
  end

end
