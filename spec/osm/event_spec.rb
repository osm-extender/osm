# encoding: utf-8
require 'spec_helper'
require 'date'

describe "Event" do

  it "Create from API data" do
    data = {
      'eventid' => 1,
      'sectionid' => 2,
      'name' => 'Event name',
      'startdate' => '2001-01-02',
      'starttime' => '12:00:00',
      'enddate' => '1970-01-01',
      'endtime' => '',
      'cost' => 'Free',
      'location' => 'Somewhere',
      'notes' => 'None',
      'archived' => '0'
    }
    event = Osm::Event.from_api(data)

    event.id.should == 1
    event.section_id.should == 2
    event.name.should == 'Event name'
    event.start.should == DateTime.new(2001, 1, 2, 12, 0, 0)
    event.finish.should == nil
    event.cost.should == 'Free'
    event.location.should == 'Somewhere'
    event.notes.should == 'None'
    event.archived.should be_false
    event.valid?.should be_true
  end

end