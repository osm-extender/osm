# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Event Attendance" do

  it "Create from API data" do
    data = {
      "scoutid" => "1",
      "firstname" => "First",
      "lastname" => "Last",
      "dob" => "1899-11-30",
      "patrolid" => "2",
      "f_1" => "a",
      "attending" => "Yes",
    }

    ea = Osm::EventAttendance.from_api(data, 3)

    ea.member_id.should == 1
    ea.grouping_id.should == 2
    ea.fields.should == {
      'firstname' => 'First',
      'lastname' => 'Last',
      'dob' => Date.new(1899, 11, 30),
      'attending' => true,
      'f_1' => 'a',
    }
    ea.row.should == 3
    ea.valid?.should be_true
  end

end
