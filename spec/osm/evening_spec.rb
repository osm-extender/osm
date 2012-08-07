# encoding: utf-8
require 'spec_helper'
require 'date'

describe "Evening" do

  it "Create" do
    data = {
      'eveningid' => 1,
      'sectionid' => 2,
      'title' => 'Evening Name',
      'notesforparents' => 'Notes for parents',
      'games' => 'Games',
      'prenotes' => 'Before',
      'postnotes' => 'After',
      'leaders' => 'Leaders',
      'starttime' => '19:00',
      'endtime' => '21:00',
      'meetingdate' => '2000-01-02',
    }
    activities = [{
      'eveningid' => 1,
      'activityid' => 2,
      'title' => 'Activity Name',
      'notes' => 'Notes',
    }]
    e = Osm::Evening.new(data, activities)

    e.evening_id.should == 1
    e.section_id.should == 2
    e.title.should == 'Evening Name'
    e.notes_for_parents.should == 'Notes for parents'
    e.games.should == 'Games'
    e.pre_notes.should == 'Before'
    e.post_notes.should == 'After'
    e.leaders.should == 'Leaders'
    e.start_time.should == '19:00'
    e.end_time.should == '21:00'
    e.meeting_date.should == Date.new(2000, 1, 2)

    e.activities.frozen?.should be_true
    ea = e.activities[0]
    ea.activity_id.should == 2
    ea.title.should == 'Activity Name'
    ea.notes.should == 'Notes'
  end


  it "Raises exceptions when trying to set invalid times" do
    e = Osm::Evening.new({}, [])
    
    expect{ e.start_time = 'abcde' }.to raise_error(ArgumentError)
    expect{ e.start_time = '24:00' }.to raise_error(ArgumentError)
    expect{ e.start_time = '10:61' }.to raise_error(ArgumentError)
    e.start_time = '12:34'
    e.start_time.should == '12:34'

    expect{ e.end_time = 'abcde' }.to raise_error(ArgumentError)
    expect{ e.end_time = '24:00' }.to raise_error(ArgumentError)
    expect{ e.end_time = '10:61' }.to raise_error(ArgumentError)
    e.end_time = '23:45'
    e.end_time.should == '23:45'
  end


  it "Creates the data for saving through the API" do
    data = {
      'eveningid' => 1,
      'sectionid' => 2,
      'title' => 'Evening Name',
      'notesforparents' => 'Notes for parents',
      'games' => 'Games',
      'prenotes' => 'Before',
      'postnotes' => 'After',
      'leaders' => 'Leaders',
      'starttime' => '19:00',
      'endtime' => '21:00',
      'meetingdate' => '2000-01-02',
    }
    activities = [{
      'eveningid' => 3,
      'activityid' => 4,
      'title' => 'Activity Name',
      'notes' => 'Notes',
    }]
    e = Osm::Evening.new(data, activities)
    e.data_for_saving.should == {
      'eveningid' => 1,
      'sectionid' => 2,
      'meetingdate' => '2000-01-02',
      'starttime' => '19:00',
      'endtime' => '21:00',
      'title' => 'Evening Name',
      'notesforparents' => 'Notes for parents',
      'prenotes' => 'Before',
      'postnotes' => 'After',
      'games' => 'Games',
      'leaders' => 'Leaders',
      'activity' => '[{"activityid":4,"notes":"Notes"}]',
    }
  end

end