# encoding: utf-8
require 'spec_helper'

describe "Grouping" do

  it "Create" do
    data = {
      'patrolid' => 1,
      'name' => 'Patrol Name',
      'active' => 1,
      'points' => '2',
    }
    patrol = Osm::Grouping.from_api(data)

    patrol.id.should == 1
    patrol.name.should == 'Patrol Name'
    patrol.active.should == true
    patrol.points.should == 2
  end

end