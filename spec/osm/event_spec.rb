# encoding: utf-8
require 'spec_helper'
require 'date'

describe "Event" do

  it "Create Event" do
    data = {
      :id => 1,
      :section_id => 2,
      :name => 'Event name',
      :start => DateTime.new(2001, 1, 2, 12 ,0 ,0),
      :finish => nil,
      :cost => 'Free',
      :location => 'Somewhere',
      :notes => 'None',
      :archived => '0',
      :fields => {},
    }
    event = Osm::Event.new(data)

    event.id.should == 1
    event.section_id.should == 2
    event.name.should == 'Event name'
    event.start.should == DateTime.new(2001, 1, 2, 12, 0, 0)
    event.finish.should == nil
    event.cost.should == 'Free'
    event.location.should == 'Somewhere'
    event.notes.should == 'None'
    event.archived.should be_false
    event.fields.should == {}
    event.valid?.should be_true
  end

  it "Create Event::Attendance" do
    data = {
      :member_id => 1,
      :grouping_id => 2,
      :row => 3,
      :fields => {},
      :event => Osm::Event.new(:id => 1, :section_id => 1, :name => 'Name', :fields => {})
    }

    ea = Osm::Event::Attendance.new(data)  
    ea.member_id.should == 1
    ea.grouping_id.should == 2
    ea.fields.should == {}
    ea.row.should == 3
    ea.valid?.should be_true
  end


  describe "Using the API" do

    before :each do
      events_body = {
        'identifier' => 'eventid',
        'label' => 'name',
        'items' => [{
          'eventid' => '2',
          'name' => 'An Event',
          'startdate' => '2001-02-03',
          'enddate' => '2001-02-05',
          'starttime' => '00:00:00',
          'endtime' => '12:00:00',
          'cost' => '0.00',
          'location' => 'Somewhere',
          'notes' => 'Notes',
          'sectionid' => 1,
          'googlecalendar' => nil,
          'archived' => '0'
        }]
      }

      fields_body = {
        'config' => '[{"id":"f_1","name":"Field 1"}]'
      }

      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/events.php?action=getEvents&sectionid=1&showArchived=true", :body => events_body.to_json)
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/events.php?action=getEvent&sectionid=1&eventid=2", :body => fields_body.to_json)

      Osm::Model.stub(:get_user_permissions) { {:events => [:read, :write]} }
    end

    it "Get events for section" do
      events = Osm::Event.get_for_section(@api, 1)
      events.size.should == 1
      event = events[0]
      event.id.should == 2
      event.section_id.should == 1
      event.name.should == 'An Event'
      event.start.should == Date.new(2001, 2, 3)
      event.finish.should == DateTime.new(2001, 2, 5, 12, 0, 0)
      event.cost.should == '0.00'
      event.location.should == 'Somewhere'
      event.notes.should == 'Notes'
      event.archived.should be_false
      event.valid?.should be_true
    end

    it "Fetch events for a section honoring archived option" do
      body = {
        'identifier' => 'eventid',
        'label' => 'name',
        'items' => [{
          'eventid' => '1',
          'name' => 'An Event',
          'startdate' => '2001-02-03',
          'enddate' => nil,
          'starttime' => '00:00:00',
          'endtime' => '00:00:00',
          'cost' => '0.00',
          'location' => '',
          'notes' => '',
          'sectionid' => 1,
          'googlecalendar' => nil,
          'archived' => '0'
        },{
          'eventid' => '2',
          'name' => 'An Archived Event',
          'startdate' => '2001-02-03',
          'enddate' => nil,
          'starttime' => '00:00:00',
          'endtime' => '00:00:00',
          'cost' => '0.00',
          'location' => '',
          'notes' => '',
          'sectionid' => 1,
          'googlecalendar' => nil,
          'archived' => '1'
        }]
      }

      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/events.php?action=getEvents&sectionid=1&showArchived=true", :body => body.to_json)
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/events.php?action=getEvent&sectionid=1&eventid=1", :body => {'config' => '[]'}.to_json)
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/events.php?action=getEvent&sectionid=1&eventid=2", :body => {'config' => '[]'}.to_json)
      Osm::Event.get_for_section(@api, 1).size.should == 1
      Osm::Event.get_for_section(@api, 1, {:include_archived => true}).size.should == 2
    end

    it "Get event" do
      event = Osm::Event.get(@api, 1, 2)
      event.should_not be_nil
      event.id.should == 2
    end


    it "Create (succeded)" do
      url = 'https://www.onlinescoutmanager.co.uk/events.php?action=addEvent&sectionid=1'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'name' => 'Test event',
        'startdate' => '2000-01-02',
        'enddate' => '2001-02-03',
        'starttime' => '03:04:05',
        'endtime' => '04:05:06',
        'cost' => '1.23',
        'location' => 'Somewhere',
        'notes' => 'none'
      }

      Osm::Event.stub(:get_for_section) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"id":2}'}) }

      event = Osm::Event.new(
        :section_id => 1,
        :name => 'Test event',
        :start => DateTime.new(2000, 01, 02, 03, 04, 05),
        :finish => DateTime.new(2001, 02, 03, 04, 05, 06),
        :cost => '1.23',
        :location => 'Somewhere',
        :notes => 'none',
        :fields => {},
      )
      event.create(@api).should == 2
    end

    it "Create (failed)" do
      Osm::Event.stub(:get_for_section) { [] }
      HTTParty.should_receive(:post) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{}'}) }

      event = Osm::Event.new(
        :section_id => 1,
        :name => 'Test event',
        :start => DateTime.new(2000, 01, 02, 03, 04, 05),
        :finish => DateTime.new(2001, 02, 03, 04, 05, 06),
        :cost => '1.23',
        :location => 'Somewhere',
        :notes => 'none',
        :fields => {},
      )
      event.create(@api).should be_nil
    end


    it "Update (succeded)" do
      url = 'https://www.onlinescoutmanager.co.uk/events.php?action=addEvent&sectionid=1'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'name' => 'Test event',
        'startdate' => '2000-01-02',
        'enddate' => '2001-02-03',
        'starttime' => '03:04:05',
        'endtime' => '04:05:06',
        'cost' => '1.23',
        'location' => 'Somewhere',
        'notes' => 'none',
        'eventid' => 2
      }

      HTTParty.should_receive(:post).with(url, {:body => post_data}) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"id":2}'}) }

      event = Osm::Event.new(
        :section_id => 1,
        :name => 'Test event',
        :start => DateTime.new(2000, 01, 02, 03, 04, 05),
        :finish => DateTime.new(2001, 02, 03, 04, 05, 06),
        :cost => '1.23',
        :location => 'Somewhere',
        :notes => 'none',
        :id => 2
      )
      event.update(@api).should be_true
    end

    it "Update (failed)" do
      HTTParty.should_receive(:post) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{}'}) }

      event = Osm::Event.new(
        :section_id => 1,
        :name => 'Test event',
        :start => DateTime.new(2000, 01, 02, 03, 04, 05),
        :finish => DateTime.new(2001, 02, 03, 04, 05, 06),
        :cost => '1.23',
        :location => 'Somewhere',
        :notes => 'none',
        :id => 2
      )
      event.update(@api).should be_false
    end


    it "Delete (succeded)" do
      url = 'https://www.onlinescoutmanager.co.uk/events.php?action=deleteEvent&sectionid=1&eventid=2'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
      }

      HTTParty.should_receive(:post).with(url, {:body => post_data}) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"ok":true}'}) }

      event = Osm::Event.new(
        :section_id => 1,
        :name => 'Test event',
        :start => DateTime.new(2000, 01, 02, 03, 04, 05),
        :finish => DateTime.new(2001, 02, 03, 04, 05, 06),
        :cost => '1.23',
        :location => 'Somewhere',
        :notes => 'none',
        :id => 2
      )
      event.delete(@api).should be_true
    end

    it "Delete (failed)" do
      HTTParty.should_receive(:post) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"ok":false}'}) }

      event = Osm::Event.new(
        :section_id => 1,
        :name => 'Test event',
        :start => DateTime.new(2000, 01, 02, 03, 04, 05),
        :finish => DateTime.new(2001, 02, 03, 04, 05, 06),
        :cost => '1.23',
        :location => 'Somewhere',
        :notes => 'none',
        :id => 2
      )
      event.delete(@api).should be_false
    end


    it "Get attendance" do
      attendance_body = {
	'identifier' => 'scoutid',
	'eventid' => '2',
	'items' => [
          {
	    'scoutid' => '1',
	    'attending' => 'Yes',
            'firstname' => 'First',
            'lastname' => 'Last',
            'dob' => '1980-01-02',
            'patrolid' => '2',
            'f_1' => 'a',
          }
        ]
      }

      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/events.php?action=getEventAttendance&eventid=2&sectionid=1&termid=3", :body => attendance_body.to_json)

      event = Osm::Event.new(:id => 2, :section_id => 1)
      event.should_not be_nil
      attendance = event.get_attendance(@api, 3)
      attendance.is_a?(Array).should be_true
      ea = attendance[0]
      ea.member_id.should == 1
      ea.grouping_id.should == 2
      ea.fields.should == {
        'firstname' => 'First',
        'lastname' => 'Last',
        'dob' => Date.new(1980, 1, 2),
        'attending' => true,
        'f_1' => 'a',
      }
      ea.row.should == 0
    end

    it "Update attendance (succeded)" do
      ea = Osm::Event::Attendance.new(:row => 0, :member_id => 4, :fields => {'f_1' => 'TEST'}, :event => Osm::Event.new(:id => 2, :section_id => 1))

      HTTParty.should_receive(:post).with(
        "https://www.onlinescoutmanager.co.uk/events.php?action=updateScout",
        {:body => {
          'scoutid' => 4,
          'column' => 'f_1',
          'value' => 'TEST',
          'sectionid' => 1,
          'row' => 0,
          'eventid' => 2,
          'apiid' => @CONFIGURATION[:api][:osm][:id],
          'token' => @CONFIGURATION[:api][:osm][:token],
          'userid' => 'user_id',
          'secret' => 'secret',
        }}
      ) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{}'}) }

      ea.update(@api, 'f_1').should be_true
    end


    it "Add field (succeded)" do
      url = 'https://www.onlinescoutmanager.co.uk/events.php?action=addColumn&sectionid=1&eventid=2'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'columnName' => 'Test field',
      }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"eventid":"2"}'}) }

      event = Osm::Event.new(:id => 2, :section_id => 1)
      event.should_not be_nil
      event.add_field(@api, 'Test field').should be_true
    end

    it "Add field (failed)" do
      HTTParty.should_receive(:post) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{}'}) }

      event = Osm::Event.new(:id => 2, :section_id => 1)
      event.should_not be_nil
      event.add_field(@api, 'Test field').should be_false
    end

  end


  describe "API Strangeness" do
    it "handles a non existant array when no events" do
      data = '{"identifier":"eventid","label":"name"}'
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/events.php?action=getEvents&sectionid=1&showArchived=true", :body => data)
      events = Osm::Event.get_for_section(@api, 1).should == []
    end
  end

end