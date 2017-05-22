# encoding: utf-8
require 'spec_helper'
require 'date'

describe "Event" do

  it "Create Event" do
    data = {
      id: 1,
      section_id: 2,
      name: 'Event name',
      start: DateTime.new(2001, 1, 2, 12 ,0 ,0),
      finish: nil,
      cost: '1.23',
      location: 'Somewhere',
      notes: 'None',
      archived: '0',
      badges: [],
      files: [],
      columns: [],
      notepad: 'notepad',
      public_notepad: 'public notepad',
      confirm_by_date: Date.new(2002, 1, 2),
      allow_changes: true,
      reminders: false,
      attendance_limit: 3,
      attendance_limit_includes_leaders: true,
      attendance_reminder: 14,
      allow_booking: false,
    }
    event = Osm::Event.new(data)

    event.id.should == 1
    event.section_id.should == 2
    event.name.should == 'Event name'
    event.start.should == DateTime.new(2001, 1, 2, 12, 0, 0)
    event.finish.should be_nil
    event.cost.should == '1.23'
    event.location.should == 'Somewhere'
    event.notes.should == 'None'
    event.archived.should == false
    event.badges.should == []
    event.files.should == []
    event.columns.should == []
    event.notepad.should == 'notepad'
    event.public_notepad.should == 'public notepad'
    event.confirm_by_date.should == Date.new(2002, 1, 2)
    event.allow_changes.should == true
    event.reminders.should == false
    event.attendance_limit.should == 3
    event.attendance_limit_includes_leaders.should == true
    event.attendance_reminder.should == 14
    event.allow_booking.should == false
    event.valid?.should == true
  end

  it "Tells if attendance is limited" do
    Osm::Event.new(attendance_limit: 0).limited_attendance?.should == false
    Osm::Event.new(attendance_limit: 1).limited_attendance?.should == true
  end

  it "Tells if the cost is TBC" do
    Osm::Event.new(cost: 'TBC').cost_tbc?.should == true
    Osm::Event.new(cost: '1.23').cost_tbc?.should == false
  end

  it "Tells if the cost is free" do
    Osm::Event.new(cost: 'TBC').cost_free?.should == false
    Osm::Event.new(cost: '1.23').cost_free?.should == false
    Osm::Event.new(cost: '0.00').cost_free?.should == true
  end

  it "Sorts by start, name then ID (unless IDs are equal)" do
    e1 = Osm::Event.new(start: '2000-01-01 01:00:00', name: 'An event', id: 1)
    e2 = Osm::Event.new(start: '2000-01-02 01:00:00', name: 'An event', id: 2)
    e3 = Osm::Event.new(start: '2000-01-02 01:00:00', name: 'Event name', id: 3)
    e4 = Osm::Event.new(start: '2000-01-02 01:00:00', name: 'Event name', id: 4)
    events = [e2, e4, e3, e1]

    events.sort.should == [e1, e2, e3, e4]
    (Osm::Event.new(id: 1) <=> Osm::Event.new(id: 1)).should == 0
  end

  describe "Event::Attendance" do 
  
    it "Create" do
      data = {
        member_id: 1,
        grouping_id: 2,
        row: 3,
        first_name: 'First',
        last_name: 'Last',
        attending: :yes,
        date_of_birth: Date.new(2000, 1, 2),
        fields: {},
        payments: {},
        event: Osm::Event.new(id: 1, section_id: 1, name: 'Name', columns: [])
      }

      ea = Osm::Event::Attendance.new(data)  
      ea.member_id.should == 1
      ea.grouping_id.should == 2
      ea.fields.should == {}
      ea.payments.should == {}
      ea.row.should == 3
      ea.first_name.should == 'First'
      ea.last_name.should == 'Last'
      ea.date_of_birth.should == Date.new(2000, 1, 2)
      ea.attending.should == :yes
      ea.valid?.should == true
    end

    it "Sorts by event ID then row" do
      ea1 = Osm::Event::Attendance.new(event: Osm::Event.new(id: 1), row: 1)
      ea2 = Osm::Event::Attendance.new(event: Osm::Event.new(id: 2), row: 1)
      ea3 = Osm::Event::Attendance.new(event: Osm::Event.new(id: 2), row: 2)
      event_attendances = [ea3, ea2, ea1]

      event_attendances.sort.should == [ea1, ea2, ea3]
    end
  
  end

  describe "Event::BadgeLink" do
  
    it "Create" do
      bl = Osm::Event::BadgeLink.new(
        badge_type: :activity,
        badge_section: :cubs,
        requirement_label: 'A: Poster',
        data: 'abc',
        badge_name: 'Artist',
        badge_id: 1,
        badge_version: 0,
        requirement_id: 2,
      )
  
      bl.badge_type.should == :activity
      bl.badge_section.should == :cubs
      bl.badge_name.should == 'Artist'
      bl.badge_id.should == 1
      bl.badge_version.should == 0
      bl.requirement_id.should == 2
      bl.requirement_label.should == 'A: Poster'
      bl.data.should == 'abc'
      bl.valid?.should == true
    end
  
  end

  describe "Using the API" do

    before :each do
      @events_body = {
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
          'archived' => '0',
          'confdate' => nil,
          'allowchanges' => '1',
          'disablereminders' => '1',
          'attendancelimit' => '3',
          'attendancereminder' => '7',
          'limitincludesleaders' => '1',
          'allowbooking' => '1',
        }]
      }

      @event_body = {
        'eventid' => '2',
        'name' => 'An Event',
        'startdate' => '2001-01-02',
        'enddate' => '2001-02-05',
        'starttime' => '00:00:00',
        'endtime' => '12:00:00',
        'cost' => '0.00',
        'location' => 'Somewhere',
        'notes' => 'Notes',
        'notepad' => 'notepad',
        'publicnotes' => 'public notepad',
        'config' => '[{"id":"f_1","name":"Name","pL":"Label","pR":"1"}]',
        'badgelinks' => [
          {"section"=>"cubs", "badgetype"=>"activity", "badge"=>"activity_athletics", "columnname"=>"b", "data"=>"Yes", "badgeLongName"=>"Athletics", "columnnameLongName"=>"B: Run", "sectionLongName"=>"Cubs", "badgetypeLongName"=>"Activity", "badge_id"=>"179", "badge_version"=>"0", "column_id"=>"3"},
          {"section"=>"staged", "badgetype"=>"staged", "badge"=>"hikes", "columnname"=>"custom", "data"=>"1", "badgeLongName"=>"Hikes", "columnnameLongName"=>"C: Hike name = 1", "sectionLongName"=>"Staged", "badgetypeLongName"=>"Staged", "badge_id"=>"197", "badge_version"=>"0", "column_id"=>"4"},
        ],
        'sectionid' => '1',
        'googlecalendar' => nil,
        'archived' => '0',
        'confdate' => '2002-01-02',
        'allowchanges' => '1',
        'disablereminders' => '1',
        'pnnotepad' => '',
        'structure' => [],
        'attendancelimit' => '3',
        'attendancereminder' => '7',
        'limitincludesleaders' => '1',
        'allowbooking' => '1',
      }

      Osm::Model.stub(:get_user_permissions) { {events: [:read, :write]} }
    end

    describe "Get events for section" do
      it "From OSM" do
        $api.should_receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        $api.should_receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        $api.should_receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=2').and_return({"files" => ["file1.txt", "file2.txt"]})
        events = Osm::Event.get_for_section(api: $api, section: 1)
        events.size.should == 1
        event = events[0]
        event.id.should == 2
        event.section_id.should == 1
        event.name.should == 'An Event'
        event.start.should == Date.new(2001, 1, 2)
        event.finish.should == DateTime.new(2001, 2, 5, 12, 0, 0)
        event.cost.should == '0.00'
        event.location.should == 'Somewhere'
        event.notes.should == 'Notes'
        event.archived.should == false
        event.notepad.should == 'notepad'
        event.public_notepad.should == 'public notepad'
        event.confirm_by_date.should == Date.new(2002, 1, 2)
        event.allow_changes.should == true
        event.reminders.should == false
        event.attendance_limit.should == 3
        event.attendance_limit_includes_leaders.should == true
        event.attendance_reminder.should == 7
        event.allow_booking.should == true
        event.columns[0].id.should == 'f_1'
        event.columns[0].name.should == 'Name'
        event.columns[0].label.should == 'Label'
        event.columns[0].parent_required.should == true
        event.badges[0].badge_name.should == 'Athletics'
        event.badges[0].badge_section.should == :cubs
        event.badges[0].badge_type.should == :activity
        event.badges[0].requirement_id.should == 3
        event.badges[0].data.should == 'Yes'
        event.badges[0].requirement_label.should == 'B: Run'
        event.badges[0].badge_id.should == 179
        event.badges[0].badge_version.should == 0
        event.badges[1].badge_name.should == 'Hikes'
        event.badges[1].badge_section.should == :staged
        event.badges[1].badge_type.should == :staged
        event.badges[1].requirement_id.should == 4
        event.badges[1].data.should == '1'
        event.files.should == ['file1.txt', 'file2.txt']
        event.valid?.should == true
      end

      it "Handles no files being an empty array not a hash" do
        $api.should_receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        expect{ @event = Osm::Event.get(api: $api, section: 1, id: 2) }.to_not raise_error
        @event.files.should == []
      end

      it "Handles a blank config" do
        @event_body['config'] = ''
        $api.should_receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        expect { @event = Osm::Event.get(api: $api, section: 1, id: 2) }.to_not raise_error
        @event.columns.should == []
      end

      it 'Handles cost of "-1" for TBC' do
        @event_body['cost'] = '-1'
        $api.should_receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        $api.should_receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        $api.should_receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=2').and_return({"files" => ["file1.txt", "file2.txt"]})

        events = Osm::Event.get_for_section(api: $api, section: 1)
        event = events[0]
        event.cost.should == 'TBC'
        event.valid?.should == true
      end

      it "From cache" do
        $api.should_receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        $api.should_receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        $api.should_receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=2').and_return({"files" => ["file1.txt", "file2.txt"]})
        events = Osm::Event.get_for_section(api: $api, section: 1)
        $api.should_not_receive(:post_query)
        Osm::Event.get_for_section(api: $api, section: 1).should == events
      end

      it "Honours archived option" do
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

        $api.should_receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').twice.and_return(body)
        $api.should_receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=1').twice.and_return({'config' => '[]', 'archived' => '0', 'eventid' => '1'})
        $api.should_receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').twice.and_return({'config' => '[]', 'archived' => '1', 'eventid' => '2'})
        $api.should_receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=1').twice.and_return({"files" => []})
        $api.should_receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=2').twice.and_return({"files" => []})

        events = Osm::Event.get_for_section(api: $api, section: 1, include_archived: false)
        OsmTest::Cache.clear
        all_events = Osm::Event.get_for_section(api: $api, section: 1, include_archived: true)

        events.size.should == 1
        events[0].id == 1
        all_events.size.should == 2
      end
    end

    describe "Get events list for section" do
      it "From OSM" do
        $api.should_receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        events = Osm::Event.get_list(api: $api, section: 1)
        events.map{ |e| e[:id]}.should == [2]
      end

      it "From cache" do
        $api.should_receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        events = Osm::Event.get_list(api: $api, section: 1)
        $api.should_not_receive(:post_query)
        Osm::Event.get_list(api: $api, section: 1).should == events
      end

      it "From cached events" do
        $api.should_receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        $api.should_receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        $api.should_receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=2').and_return({"files" => ["file1.txt", "file2.txt"]})
        Osm::Event.get_for_section(api: $api, section: 1)
        $api.should_not_receive(:post_query)
        events = Osm::Event.get_list(api: $api, section: 1)
        events.map{ |e| e[:id]}.should == [2]
      end

    end # describe get events list for section


    it "Get event" do
      $api.should_receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
      event = Osm::Event.get(api: $api, section: 1, id: 2)
      event.should_not be_nil
      event.id.should == 2
    end

    describe "Tells if there are spaces" do

      it "No limit" do
        $api.should_not_receive(:post_query)
        event = Osm::Event.new(attendance_limit: 0, id: 1, section_id: 2)
        event.spaces?($api).should == true
        event.spaces($api).should be_nil
      end

      it "Under limit" do
        $api.should_receive(:post_query).with('events.php?action=getEventAttendance&eventid=1&sectionid=2&termid=3').and_return({
          'identifier' => 'scoutid',
          'eventid' => '1',
          'items' => [
            {
              'scoutid' => '4',
              'attending' => 'Yes',
              'firstname' => 'First',
              'lastname' => 'Last',
              'dob' => '1980-01-02',
              'patrolid' => '2',
              'f_1' => 'a',
            },
          ]
        })
        Osm::Term.stub(:get_current_term_for_section) { Osm::Term.new(id: 3) }

        event = Osm::Event.new(attendance_limit: 2, id: 1, section_id: 2)
        event.spaces?($api).should == true
        event.spaces($api).should == 1
      end

      it "Over limit" do
        $api.should_receive(:post_query).with('events.php?action=getEventAttendance&eventid=1&sectionid=2&termid=3').and_return({
          'identifier' => 'scoutid',
          'eventid' => '1',
          'items' => [
            {
              'scoutid' => '4',
              'attending' => 'Yes',
              'firstname' => 'First',
              'lastname' => 'Last',
              'dob' => '1980-01-02',
              'patrolid' => '2',
              'f_1' => 'a',
            },{
              'scoutid' => '5',
              'attending' => 'Yes',
              'firstname' => 'First',
              'lastname' => 'Last',
              'dob' => '1980-01-02',
              'patrolid' => '2',
              'f_1' => 'a',
            },{
              'scoutid' => '6',
              'attending' => 'Yes',
              'firstname' => 'First',
              'lastname' => 'Last',
              'dob' => '1980-01-02',
              'patrolid' => '2',
              'f_1' => 'a',
            }
          ]
        })
        Osm::Term.stub(:get_current_term_for_section) { Osm::Term.new(id: 3) }

        event = Osm::Event.new(attendance_limit: 2, id: 1, section_id: 2)
        event.spaces?($api).should == false
        event.spaces($api).should == -1
      end

      it "At limit" do
        $api.should_receive(:post_query).with('events.php?action=getEventAttendance&eventid=1&sectionid=2&termid=3').and_return({
          'identifier' => 'scoutid',
          'eventid' => '1',
          'items' => [
            {
              'scoutid' => '4',
              'attending' => 'Yes',
              'firstname' => 'First',
              'lastname' => 'Last',
              'dob' => '1980-01-02',
              'patrolid' => '2',
              'f_1' => 'a',
            },{
              'scoutid' => '5',
              'attending' => 'Yes',
              'firstname' => 'First',
              'lastname' => 'Last',
              'dob' => '1980-01-02',
              'patrolid' => '2',
              'f_1' => 'a',
            }
          ]
        })
        Osm::Term.stub(:get_current_term_for_section) { Osm::Term.new(id: 3) }

        event = Osm::Event.new(attendance_limit: 2, id: 1, section_id: 2)
        event.spaces?($api).should == false
        event.spaces($api).should == 0
      end

    end

    describe "Create (succeded)" do

      it "Normal" do
        post_data = {
          'name' => 'Test event',
          'startdate' => '2000-01-02',
          'enddate' => '2001-02-03',
          'starttime' => '03:04:05',
          'endtime' => '04:05:06',
          'cost' => '1.23',
          'location' => 'Somewhere',
          'notes' => 'none',
          'confdate' => '2000-01-01',
          'allowChanges' => 'true',
          'disablereminders' => 'false',
          'attendancelimit' => 3,
          'limitincludesleaders' => 'true',
          'allowbooking' => 'true',
          'attendancereminder' => 1,
        }

        Osm::Event.stub(:get_for_section) { [] }
        $api.should_receive(:post_query).with('events.php?action=addEvent&sectionid=1', post_data: post_data).and_return({"id" => 2})

        event = Osm::Event.create(
          api: $api,
          section_id: 1,
          name: 'Test event',
          start: DateTime.new(2000, 1, 2, 3, 4, 5),
          finish: DateTime.new(2001, 2, 3, 4, 5, 6),
          cost: '1.23',
          location: 'Somewhere',
          notes: 'none',
          badges: [],
          columns: [],
          notepad: '',
          public_notepad: '',
          confirm_by_date: Date.new(2000, 1, 1),
          allow_changes: true,
          reminders: true,
          attendance_limit: 3,
          attendance_limit_includes_leaders: true,
          attendance_reminder: 1,
          allow_booking: true,
        )
        event.should_not be_nil
        event.id.should == 2
      end

      it "TBC cost" do
        post_data = {
          'name' => 'Test event',
          'startdate' => '2000-01-02',
          'enddate' => '2001-02-03',
          'starttime' => '03:04:05',
          'endtime' => '04:05:06',
          'cost' => '-1',
          'location' => 'Somewhere',
          'notes' => 'none',
          'confdate' => '2000-01-01',
          'allowChanges' => 'true',
          'disablereminders' => 'false',
          'attendancelimit' => 3,
          'attendancereminder' => 0,
          'limitincludesleaders' => 'true',
          'allowbooking' => 'true',
        }

        Osm::Event.stub(:get_for_section) { [] }
        $api.should_receive(:post_query).with('events.php?action=addEvent&sectionid=1', post_data: post_data).and_return({"id" => 2})

        event = Osm::Event.create(
          api: $api,
          section_id: 1,
          name: 'Test event',
          start: DateTime.new(2000, 1, 2, 3, 4, 5),
          finish: DateTime.new(2001, 2, 3, 4, 5, 6),
          cost: 'TBC',
          location: 'Somewhere',
          notes: 'none',
          badges: [],
          columns: [],
          notepad: '',
          public_notepad: '',
          confirm_by_date: Date.new(2000, 1, 1),
          allow_changes: true,
          reminders: true,
          attendance_limit: 3,
          attendance_limit_includes_leaders: true,
          allow_booking: true,
        )
        event.should_not be_nil
        event.id.should == 2
      end

      describe "With badges" do

        before :each do
          post_data = {
            'name' => 'Test event',
            'startdate' => '2000-01-02',
            'enddate' => '2001-02-03',
            'starttime' => '03:04:05',
            'endtime' => '04:05:06',
            'cost' => '1.23',
            'location' => 'Somewhere',
            'notes' => 'none',
            'confdate' => '2000-01-01',
            'allowChanges' => 'true',
            'disablereminders' => 'false',
            'attendancelimit' => 3,
            'limitincludesleaders' => 'true',
            'allowbooking' => 'true',
            'attendancereminder' => 1,
          }

          Osm::Event.stub(:get_for_section) { [] }
          $api.should_receive(:post_query).with('events.php?action=addEvent&sectionid=1', post_data: post_data).and_return({"id" => 2})

          @attributes = {
            section_id: 1,
            name: 'Test event',
            start: DateTime.new(2000, 1, 2, 3, 4, 5),
            finish: DateTime.new(2001, 2, 3, 4, 5, 6),
            cost: '1.23',
            location: 'Somewhere',
            notes: 'none',
            badges: [],
            columns: [],
            notepad: '',
            public_notepad: '',
            confirm_by_date: Date.new(2000, 1, 1),
            allow_changes: true,
            reminders: true,
            attendance_limit: 3,
            attendance_limit_includes_leaders: true,
            attendance_reminder: 1,
            allow_booking: true,
          }
          @badge_path = 'ext/badges/records/index.php?action=linkBadgeToItem&sectionid=1'
        end

        it "'Normal badge'" do
          post_data = {
            'type' => 'event',
            'id' => 2,
            'section' => :beavers,
            'sectionid' => 1,
            'badge_id' => 3,
            'badge_version' => 2,
            'column_id' => 1,
            'column_data' => '',
            'new_column_name' => '',
          }
          $api.should_receive(:post_query).with(@badge_path, post_data: post_data).and_return({"status" => true})

          @attributes[:badges] = [Osm::Event::BadgeLink.new(
            badge_type: :activity,
            badge_section: :beavers,
            requirement_label: '',
            data: '',
            badge_name: 'Test badge',
            badge_id: 3,
            badge_version: 2,
            requirement_id: 1,
          )]
          event = Osm::Event.create(api: $api, **@attributes)
          event.should_not be_nil
          event.id.should == 2
        end

        it "Add a hikes column" do
          post_data = {
            'type' => 'event',
            'id' => 2,
            'section' => :beavers,
            'sectionid' => 1,
            'badge_id' => 3,
            'badge_version' => 2,
            'column_id' => -2,
            'column_data' => '1',
            'new_column_name' => 'Label for added column',
          }
          $api.should_receive(:post_query).with(@badge_path, post_data: post_data).and_return({"status" => true})

          @attributes[:badges] = [Osm::Event::BadgeLink.new(
            badge_type: :staged,
            badge_section: :beavers,
            requirement_label: 'Label for added column',
            data: '1',
            badge_name: 'Test badge',
            badge_id: 3,
            badge_version: 2,
          )]
          event = Osm::Event.create(api: $api, **@attributes)
          event.should_not be_nil
          event.id.should == 2
        end

        it "Existing nights away column" do
          post_data = {
            'type' => 'event',
            'id' => 2,
            'section' => :beavers,
            'sectionid' => 1,
            'badge_id' => 3,
            'badge_version' => 2,
            'column_id' => 4,
            'column_data' => '2',
            'new_column_name' => '',
          }
          $api.should_receive(:post_query).with(@badge_path, post_data: post_data).and_return({"status" => true})

          @attributes[:badges] = [Osm::Event::BadgeLink.new(
            badge_type: :staged,
            badge_section: :beavers,
            requirement_label: '',
            data: '2',
            badge_name: 'Test badge',
            badge_id: 3,
            badge_version: 2,
            requirement_id: 4,
          )]
          event = Osm::Event.create(api: $api, **@attributes)
          event.should_not be_nil
          event.id.should == 2
        end

      end

    end

    it "Create (failed)" do
      Osm::Event.stub(:get_for_section) { [] }
      $api.should_receive(:post_query).and_return({})

      event = Osm::Event.create(
        api: $api,
        section_id: 1,
        name: 'Test event',
        start: DateTime.new(2000, 01, 02, 03, 04, 05),
        finish: DateTime.new(2001, 02, 03, 04, 05, 06),
        cost: '1.23',
        location: 'Somewhere',
        notes: 'none',
        columns: [],
        notepad: '',
        public_notepad: '',
        confirm_by_date: nil,
        allow_changes: true,
        reminders: true,
      )
      event.should be_nil
    end


    describe "Update (succeded)" do

      it "Normal" do
        post_data = {
          'name' => 'Test event',
          'startdate' => '2000-01-02',
          'enddate' => '2001-02-03',
          'starttime' => '03:04:05',
          'endtime' => '04:05:06',
          'cost' => '1.23',
          'location' => 'Somewhere',
          'notes' => 'none',
          'eventid' => 2,
          'confdate' => '',
          'allowChanges' => 'true',
          'disablereminders' => 'false',
          'attendancelimit' => 3,
          'attendancereminder' => 2,
          'limitincludesleaders' => 'true',
          'allowbooking' => 'true',
        }

        $api.should_receive(:post_query).with('events.php?action=addEvent&sectionid=1', post_data: post_data).and_return({"id" => 2})
        $api.should_receive(:post_query).with('events.php?action=saveNotepad&sectionid=1', post_data: {"eventid"=>2, "notepad"=>"notepad"}).and_return({})
        $api.should_receive(:post_query).with('events.php?action=saveNotepad&sectionid=1', post_data: {"eventid"=>2, "pnnotepad"=>"public notepad"}).and_return({})

        event = Osm::Event.new(
          section_id: 1,
          name: '',
          start: DateTime.new(2000, 01, 02, 03, 04, 05),
          finish: DateTime.new(2001, 02, 03, 04, 05, 06),
          cost: '1.23',
          location: 'Somewhere',
          notes: 'none',
          id: 2,
          confirm_by_date: nil,
          allow_changes: true,
          reminders: true,
          notepad: '',
          public_notepad: '',
          attendance_limit: 3,
          attendance_limit_includes_leaders: true,
          attendance_reminder: 2,
          allow_booking: true,
        )
        event.name = 'Test event'
        event.notepad = 'notepad'
        event.public_notepad = 'public notepad'
        event.update($api).should == true
      end

      it "TBC cost" do
        post_data = {
          'name' => 'Test event',
          'startdate' => '2000-01-02',
          'enddate' => '2001-02-03',
          'starttime' => '03:04:05',
          'endtime' => '04:05:06',
          'cost' => '-1',
          'location' => 'Somewhere',
          'notes' => 'none',
          'eventid' => 2,
          'confdate' => '',
          'allowChanges' => 'true',
          'disablereminders' => 'false',
          'attendancelimit' => 3,
          'attendancereminder' => 1,
          'limitincludesleaders' => 'true',
          'allowbooking' => 'true',
        }

        $api.should_receive(:post_query).with('events.php?action=addEvent&sectionid=1', post_data: post_data).and_return({"id" => 2})

        event = Osm::Event.new(
          section_id: 1,
          name: 'Test event',
          start: DateTime.new(2000, 01, 02, 03, 04, 05),
          finish: DateTime.new(2001, 02, 03, 04, 05, 06),
          cost: '1.23',
          location: 'Somewhere',
          notes: 'none',
          id: 2,
          confirm_by_date: nil,
          allow_changes: true,
          reminders: true,
          notepad: '',
          public_notepad: '',
          attendance_limit: 3,
          attendance_limit_includes_leaders: true,
          attendance_reminder: 1,
          allow_booking: true,
        )
        event.cost = 'TBC'
        event.update($api).should == true
      end

      describe "Badge links" do

        before :each do
          @event = Osm::Event.new({
            id: 2,
            section_id: 1,
            name: 'Test event',
            start: DateTime.new(2000, 1, 2, 3, 4, 5),
            finish: DateTime.new(2001, 2, 3, 4, 5, 6),
            cost: '1.23',
            location: 'Somewhere',
            notes: 'none',
            badges: [Osm::Event::BadgeLink.new(
              badge_type: :activity,
              badge_section: :scouts,
              requirement_label: 'A: Paint',
              data: 'Yes',
              badge_name: 'Artist',
              badge_id: 3,
              badge_version: 2,
              requirement_id: 4,
            )],
            columns: [],
            notepad: '',
            public_notepad: '',
            confirm_by_date: Date.new(2000, 1, 1),
            allow_changes: true,
            reminders: true,
            attendance_limit: 3,
            attendance_limit_includes_leaders: true,
            attendance_reminder: 1,
            allow_booking: true,
          })
        end

        it "Added" do
          badge = Osm::Event::BadgeLink.new(
            badge_type: :activity,
            badge_section: :scouts,
            requirement_label: 'A: Draw',
            data: 'Yes',
            badge_name: 'Artist',
            badge_id: 3,
            badge_version: 2,
            requirement_id: 6,
          )
          @event.should_receive(:add_badge_link).with(api: $api, link: badge) { true }

          @event.badges.push(badge)
          @event.update($api).should == true
        end

        it "Removed" do
          post_data = {
            'section' => :scouts,
            'sectionid' => 1,
            'type' => 'event',
            'id' => 2,
            'badge_id' => 3,
            'badge_version' => 2,
            'column_id' => 4,
          }
          $api.should_receive(:post_query).with('ext/badges/records/index.php?action=deleteBadgeLink&sectionid=1', post_data: post_data).and_return({"status" => true})

          @event.badges = []
          @event.update($api).should == true
        end

      end

    end

    it "Update (failed)" do
      $api.should_receive(:post_query).exactly(1).times.and_return({})

      event = Osm::Event.new(
        section_id: 1,
        name: 'Test event',
        start: DateTime.new(2000, 01, 02, 03, 04, 05),
        finish: DateTime.new(2001, 02, 03, 04, 05, 06),
        cost: '1.23',
        location: 'Somewhere',
        notes: 'none',
        id: 2
      )
      event.id = 22
      event.update($api).should == false
    end


    it "Delete (succeded)" do
      $api.should_receive(:post_query).with('events.php?action=deleteEvent&sectionid=1&eventid=2').and_return({"ok" => true})

      event = Osm::Event.new(
        section_id: 1,
        name: 'Test event',
        start: DateTime.new(2000, 01, 02, 03, 04, 05),
        finish: DateTime.new(2001, 02, 03, 04, 05, 06),
        cost: '1.23',
        location: 'Somewhere',
        notes: 'none',
        id: 2
      )
      event.delete($api).should == true
    end

    it "Delete (failed)" do
      $api.should_receive(:post_query).with('events.php?action=deleteEvent&sectionid=1&eventid=2').and_return({"ok" => false})

      event = Osm::Event.new(
        section_id: 1,
        name: 'Test event',
        start: DateTime.new(2000, 01, 02, 03, 04, 05),
        finish: DateTime.new(2001, 02, 03, 04, 05, 06),
        cost: '1.23',
        location: 'Somewhere',
        notes: 'none',
        id: 2
      )
      event.delete($api).should == false
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
            'payment' => 'Manual',
            'p1' => ''
          }
        ]
      }

      $api.should_receive(:post_query).with('events.php?action=getEventAttendance&eventid=2&sectionid=1&termid=3').and_return(attendance_body)

      event = Osm::Event.new(id: 2, section_id: 1)
      attendance = event.get_attendance(api: $api, term: 3)
      attendance.is_a?(Array).should == true
      ea = attendance[0]
      ea.member_id.should == 1
      ea.grouping_id.should == 2
      ea.first_name.should == 'First'
      ea.last_name.should == 'Last'
      ea.date_of_birth.should == Date.new(1980, 1, 2)
      ea.attending.should == :yes
      ea.fields.should == {
        1 => 'a',
      }
      ea.payments.should == {
        1 => '',
      }
      ea.row.should == 0
    end

    it "Get attendance (no items)" do
      attendance_body = {
      	'identifier' => 'scoutid',
	      'eventid' => '2',
      }

      $api.should_receive(:post_query).with('events.php?action=getEventAttendance&eventid=2&sectionid=1&termid=3').and_return(attendance_body)

      event = Osm::Event.new(id: 2, section_id: 1)
      attendance = event.get_attendance(api: $api, term: 3)
      attendance.should == []
    end

    it "Update attendance (succeded)" do
      ea = Osm::Event::Attendance.new(row: 0, member_id: 4, fields: {1 => 'old value', 2 => 'another old value'}, event: Osm::Event.new(id: 2, :section_id => 1))

      ea.fields[1] = 'value'
      $api.should_receive(:post_query).with(
        'events.php?action=updateScout',
        post_data: {
          'scoutid' => 4,
          'column' => 'f_1',
          'value' => 'value',
          'sectionid' => 1,
          'row' => 0,
          'eventid' => 2,
        }).and_return({})

      ea.attending = :yes
      $api.should_receive(:post_query).with(
        'events.php?action=updateScout',
        post_data: {
          'scoutid' => 4,
          'column' => 'attending',
          'value' => 'Yes',
          'sectionid' => 1,
          'row' => 0,
          'eventid' => 2,
        }).and_return({})

      ea.payment_control = :automatic
      $api.should_receive(:post_query).with(
        'events.php?action=updateScout',
        post_data: {
          'scoutid' => 4,
          'column' => 'payment',
          'value' => 'Automatic',
          'sectionid' => 1,
          'row' => 0,
          'eventid' => 2,
        }).and_return({})

      ea.update($api).should == true
    end


    it "Add column (succeded)" do
      post_data = {
        'columnName' => 'Test name',
        'parentLabel' => 'Test label',
        'parentRequire' => 1
      }
      body = {
        'eventid' => '2',
        'config' => '[{"id":"f_1","name":"Test name","pL":"Test label"}]'
      }
      $api.should_receive(:post_query).with('events.php?action=addColumn&sectionid=1&eventid=2', post_data: post_data).and_return(body)

      event = Osm::Event.new(id: 2, section_id: 1)
      event.should_not be_nil
      event.add_column(api: $api, name: 'Test name', label: 'Test label', required: true).should == true
      column = event.columns[0]
      column.id.should == 'f_1'
      column.name.should == 'Test name'
      column.label.should == 'Test label'
    end

    it "Add column (failed)" do
      $api.should_receive(:post_query).and_return({"config" => "[]"})

      event = Osm::Event.new(id: 2, section_id: 1)
      event.should_not be_nil
      event.add_column(api: $api, name: 'Test name', label: 'Test label').should == false
    end


    it "Update column (succeded)" do
      post_data = {
        'columnId' => 'f_1',
        'columnName' => 'New name',
        'pL' => 'New label',
        'pR' => 1
      }
      body = {
        'eventid' => '2',
        'config' => '[{"id":"f_1","name":"New name","pL":"New label","pR":"1"}]'
      }
      $api.should_receive(:post_query).with('events.php?action=renameColumn&sectionid=1&eventid=2', post_data: post_data).and_return(body)

      event = Osm::Event.new(id: 2, section_id: 1)
      event.columns = [Osm::Event::Column.new(id: 'f_1', event: event)]
      column = event.columns[0]
      column.name = 'New name'
      column.label = 'New label'
      column.parent_required = true

      column.update($api).should == true

      column.name.should == 'New name'
      column.label.should == 'New label'
      event.columns[0].name.should == 'New name'
      event.columns[0].label.should == 'New label'
    end

    it "Update column (failed)" do
      $api.should_receive(:post_query).and_return({"config" => "[]"})

      event = Osm::Event.new(id: 2, section_id: 1)
      column = Osm::Event::Column.new(id: 'f_1', event: event)
      event.columns = [column]
      column.update($api).should == false
    end


    it "Delete column (succeded)" do
      post_data = {
        'columnId' => 'f_1'
      }

      $api.should_receive(:post_query).with('events.php?action=deleteColumn&sectionid=1&eventid=2', post_data: post_data).and_return({"eventid" => "2", "config" => "[]"})

      event = Osm::Event.new(id: 2, section_id: 1)
      column = Osm::Event::Column.new(id: 'f_1', event: event)
      event.columns = [column]

      column.delete($api).should == true
      event.columns.should == []
    end

    it "Delete column (failed)" do
      $api.should_receive(:post_query).and_return({"config" => '[{"id":"f_1"}]'})

      event = Osm::Event.new(id: 2, section_id: 1)
      column = Osm::Event::Column.new(id: 'f_1', event: event)
      event.columns = [column]
      column.delete($api).should == false
    end

    it "Get audit trail" do
      data = [
      	{"date" => "10/06/2013 19:17","updatedby" => "My.SCOUT","type" => "detail","desc" => "Set 'Test' to 'Test data'"},
      	{"date" => "10/06/2013 19:16","updatedby" => "My.SCOUT","type" => "attendance","desc" => "Attendance: Yes"},
	      {"date" => "10/06/2013 19:15","updatedby" => "A Leader ","type" => "attendance","desc" => "Attendance: Reserved"},
	      {"date" => "10/06/2013 19:14","updatedby" => "A Leader ","type" => "attendance","desc" => "Attendance: No"},
	      {"date" => "10/06/2013 19:13","updatedby" => "A Leader ","type" => "attendance","desc" => "Attendance: Yes"},
	      {"date" => "10/06/2013 19:12","updatedby" => "A Leader ","type" => "attendance","desc" => "Attendance: Invited"},
	      {"date" => "10/06/2013 19:11","updatedby" => "A Leader ","type" => "attendance","desc" => "Attendance: Show in My.SCOUT"},
      ]

      $api.should_receive(:post_query).with('events.php?action=getEventAudit&sectionid=1&scoutid=2&eventid=3').and_return(data)

      ea = Osm::Event::Attendance.new(
        event: Osm::Event.new(id: 3, section_id: 1),
        member_id: 2,
      )
      ea.get_audit_trail($api).should == [
        {event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 17), by: 'My.SCOUT', :type => :detail, :description => "Set 'Test' to 'Test data'", :label => 'Test', :value => 'Test data'},
        {event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 16), by: 'My.SCOUT', :type => :attendance, :description => "Attendance: Yes", :attendance => :yes},
        {event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 15), by: 'A Leader', :type => :attendance, :description => "Attendance: Reserved", :attendance => :reserved},
        {event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 14), by: 'A Leader', :type => :attendance, :description => "Attendance: No", :attendance => :no},
        {event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 13), by: 'A Leader', :type => :attendance, :description => "Attendance: Yes", :attendance => :yes},
        {event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 12), by: 'A Leader', :type => :attendance, :description => "Attendance: Invited", :attendance => :invited},
        {event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 11), by: 'A Leader', :type => :attendance, :description => "Attendance: Show in My.SCOUT", :attendance => :shown},
      ]
    end

  end


  describe "API Strangeness" do

    it "Handles a non existant array when no events" do
      data = {"identifier" => "eventid", "label" => "name"}
      $api.should_receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(data)
      events = Osm::Event.get_for_section(api: $api, section: 1).should == []
    end

    it "Handles missing config from OSM" do
      events_body = {"identifier" => "eventid", "label" => "name", "items" => [{"eventid"=>"2","name"=>"An Event","startdate"=>"2001-02-03","enddate"=>"2001-02-05","starttime"=>"00:00:00","endtime"=>"12:00:00","cost"=>"0.00","location"=>"Somewhere","notes"=>"Notes","sectionid"=>1,"googlecalendar"=>nil,"archived"=>"0","confdate"=>nil,"allowchanges"=>"1","disablereminders"=>"1","attendancelimit"=>"3","limitincludesleaders"=>"1"}]}
      event_body = {
        'eventid' => '2',
        'name' => 'An Event',
        'startdate' => '2001-01-02',
        'enddate' => '2001-02-05',
        'starttime' => '00:00:00',
        'endtime' => '12:00:00',
        'cost' => '0.00',
        'location' => 'Somewhere',
        'notes' => 'Notes',
        'notepad' => 'notepad',
        'publicnotes' => 'public notepad',
        'sectionid' => '1',
        'googlecalendar' => nil,
        'archived' => '0',
        'confdate' => '2002-01-02',
        'allowchanges' => '1',
        'disablereminders' => '1',
        'pnnotepad' => '',
        'structure' => [],
        'attendancelimit' => '3',
        'limitincludesleaders' => '1',
      }

      $api.should_receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(event_body)

      Osm::Model.stub(:get_user_permissions) { {events: [:read, :write]} }

      event = Osm::Event.get(api: $api, section: 1, id: 2)
      event.should_not be_nil
      event.id.should == 2
      event.columns.should == []
    end

  end

end
