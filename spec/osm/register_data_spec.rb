# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Register Data" do

  it "Create" do
    data = {
      'scoutid' => '1',
      'firstname' => 'A',
      'lastname' => 'B',
      'sectionid' => '2',
      'patrolid' => '3',
      'total' => 4,
      '2012-01-10' => 'Yes',
      '2012-01-24' => 'No',
    }

    rd = Osm::RegisterData.new(data)

    rd.member_id.should == 1
    rd.section_id.should == 2
    rd.grouping_id.should == 3
    rd.first_name.should == 'A'
    rd.last_name.should == 'B'
    rd.total.should == 4
    rd.attendance.should == {
      Date.new(2012, 01, 10) => 'Yes',
      Date.new(2012, 01, 24) => 'No'
    }
  end

end
