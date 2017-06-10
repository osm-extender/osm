describe Osm::Event do

  it 'Create Event' do
    data = {
      id: 1,
      section_id: 2,
      name: 'Event name',
      start: DateTime.new(2001, 1, 2, 12,0,0),
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

    expect(event.id).to eq(1)
    expect(event.section_id).to eq(2)
    expect(event.name).to eq('Event name')
    expect(event.start).to eq(DateTime.new(2001, 1, 2, 12, 0, 0))
    expect(event.finish).to be_nil
    expect(event.cost).to eq('1.23')
    expect(event.location).to eq('Somewhere')
    expect(event.notes).to eq('None')
    expect(event.archived).to eq(false)
    expect(event.badges).to eq([])
    expect(event.files).to eq([])
    expect(event.columns).to eq([])
    expect(event.notepad).to eq('notepad')
    expect(event.public_notepad).to eq('public notepad')
    expect(event.confirm_by_date).to eq(Date.new(2002, 1, 2))
    expect(event.allow_changes).to eq(true)
    expect(event.reminders).to eq(false)
    expect(event.attendance_limit).to eq(3)
    expect(event.attendance_limit_includes_leaders).to eq(true)
    expect(event.attendance_reminder).to eq(14)
    expect(event.allow_booking).to eq(false)
    expect(event.valid?).to eq(true)
  end

  it 'Tells if attendance is limited' do
    expect(Osm::Event.new(attendance_limit: 0).limited_attendance?).to eq(false)
    expect(Osm::Event.new(attendance_limit: 1).limited_attendance?).to eq(true)
  end

  it 'Tells if the cost is TBC' do
    expect(Osm::Event.new(cost: 'TBC').cost_tbc?).to eq(true)
    expect(Osm::Event.new(cost: '1.23').cost_tbc?).to eq(false)
  end

  it 'Tells if the cost is free' do
    expect(Osm::Event.new(cost: 'TBC').cost_free?).to eq(false)
    expect(Osm::Event.new(cost: '1.23').cost_free?).to eq(false)
    expect(Osm::Event.new(cost: '0.00').cost_free?).to eq(true)
  end

  it 'Sorts by start, name then ID (unless IDs are equal)' do
    e1 = Osm::Event.new(start: '2000-01-01 01:00:00', name: 'An event', id: 1)
    e2 = Osm::Event.new(start: '2000-01-02 01:00:00', name: 'An event', id: 2)
    e3 = Osm::Event.new(start: '2000-01-02 01:00:00', name: 'Event name', id: 3)
    e4 = Osm::Event.new(start: '2000-01-02 01:00:00', name: 'Event name', id: 4)
    events = [e2, e4, e3, e1]

    expect(events.sort).to eq([e1, e2, e3, e4])
    expect(Osm::Event.new(id: 1) <=> Osm::Event.new(id: 1)).to eq(0)
  end


  describe 'Using the API' do

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
          { 'section'=>'cubs', 'badgetype'=>'activity', 'badge'=>'activity_athletics', 'columnname'=>'b', 'data'=>'Yes', 'badgeLongName'=>'Athletics', 'columnnameLongName'=>'B: Run', 'sectionLongName'=>'Cubs', 'badgetypeLongName'=>'Activity', 'badge_id'=>'179', 'badge_version'=>'0', 'column_id'=>'3' },
          { 'section'=>'staged', 'badgetype'=>'staged', 'badge'=>'hikes', 'columnname'=>'custom', 'data'=>'1', 'badgeLongName'=>'Hikes', 'columnnameLongName'=>'C: Hike name = 1', 'sectionLongName'=>'Staged', 'badgetypeLongName'=>'Staged', 'badge_id'=>'197', 'badge_version'=>'0', 'column_id'=>'4' },
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

      allow(Osm::Model).to receive(:get_user_permissions) { { events: [:read, :write] } }
    end

    describe 'Get events for section' do
      it 'From OSM' do
        expect($api).to receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        expect($api).to receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        expect($api).to receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=2').and_return('files' => ['file1.txt', 'file2.txt'])
        events = Osm::Event.get_for_section(api: $api, section: 1)
        expect(events.size).to eq(1)
        event = events[0]
        expect(event.id).to eq(2)
        expect(event.section_id).to eq(1)
        expect(event.name).to eq('An Event')
        expect(event.start).to eq(Date.new(2001, 1, 2))
        expect(event.finish).to eq(DateTime.new(2001, 2, 5, 12, 0, 0))
        expect(event.cost).to eq('0.00')
        expect(event.location).to eq('Somewhere')
        expect(event.notes).to eq('Notes')
        expect(event.archived).to eq(false)
        expect(event.notepad).to eq('notepad')
        expect(event.public_notepad).to eq('public notepad')
        expect(event.confirm_by_date).to eq(Date.new(2002, 1, 2))
        expect(event.allow_changes).to eq(true)
        expect(event.reminders).to eq(false)
        expect(event.attendance_limit).to eq(3)
        expect(event.attendance_limit_includes_leaders).to eq(true)
        expect(event.attendance_reminder).to eq(7)
        expect(event.allow_booking).to eq(true)
        expect(event.columns[0].id).to eq('f_1')
        expect(event.columns[0].name).to eq('Name')
        expect(event.columns[0].label).to eq('Label')
        expect(event.columns[0].parent_required).to eq(true)
        expect(event.badges[0].badge_name).to eq('Athletics')
        expect(event.badges[0].badge_section).to eq(:cubs)
        expect(event.badges[0].badge_type).to eq(:activity)
        expect(event.badges[0].requirement_id).to eq(3)
        expect(event.badges[0].data).to eq('Yes')
        expect(event.badges[0].requirement_label).to eq('B: Run')
        expect(event.badges[0].badge_id).to eq(179)
        expect(event.badges[0].badge_version).to eq(0)
        expect(event.badges[1].badge_name).to eq('Hikes')
        expect(event.badges[1].badge_section).to eq(:staged)
        expect(event.badges[1].badge_type).to eq(:staged)
        expect(event.badges[1].requirement_id).to eq(4)
        expect(event.badges[1].data).to eq('1')
        expect(event.files).to eq(['file1.txt', 'file2.txt'])
        expect(event.valid?).to eq(true)
      end

      it 'Handles no files being an empty array not a hash' do
        expect($api).to receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        expect{ @event = Osm::Event.get(api: $api, section: 1, id: 2) }.to_not raise_error
        expect(@event.files).to eq([])
      end

      it 'Handles a blank config' do
        @event_body['config'] = ''
        expect($api).to receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        expect { @event = Osm::Event.get(api: $api, section: 1, id: 2) }.to_not raise_error
        expect(@event.columns).to eq([])
      end

      it 'Handles cost of "-1" for TBC' do
        @event_body['cost'] = '-1'
        expect($api).to receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        expect($api).to receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        expect($api).to receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=2').and_return('files' => ['file1.txt', 'file2.txt'])

        events = Osm::Event.get_for_section(api: $api, section: 1)
        event = events[0]
        expect(event.cost).to eq('TBC')
        expect(event.valid?).to eq(true)
      end

      it 'From cache' do
        expect($api).to receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        expect($api).to receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        expect($api).to receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=2').and_return('files' => ['file1.txt', 'file2.txt'])
        events = Osm::Event.get_for_section(api: $api, section: 1)
        expect($api).not_to receive(:post_query)
        expect(Osm::Event.get_for_section(api: $api, section: 1)).to eq(events)
      end

      it 'Honours archived option' do
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

        expect($api).to receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').twice.and_return(body)
        expect($api).to receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=1').twice.and_return('config' => '[]', 'archived' => '0', 'eventid' => '1')
        expect($api).to receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').twice.and_return('config' => '[]', 'archived' => '1', 'eventid' => '2')
        expect($api).to receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=1').twice.and_return('files' => [])
        expect($api).to receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=2').twice.and_return('files' => [])

        events = Osm::Event.get_for_section(api: $api, section: 1, include_archived: false)
        OsmTest::Cache.clear
        all_events = Osm::Event.get_for_section(api: $api, section: 1, include_archived: true)

        expect(events.size).to eq(1)
        events[0].id == 1
        expect(all_events.size).to eq(2)
      end
    end

    describe 'Get events list for section' do
      it 'From OSM' do
        expect($api).to receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        events = Osm::Event.get_list(api: $api, section: 1)
        expect(events.map{ |e| e[:id]}).to eq([2])
      end

      it 'From cache' do
        expect($api).to receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        events = Osm::Event.get_list(api: $api, section: 1)
        expect($api).not_to receive(:post_query)
        expect(Osm::Event.get_list(api: $api, section: 1)).to eq(events)
      end

      it 'From cached events' do
        expect($api).to receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(@events_body)
        expect($api).to receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
        expect($api).to receive(:post_query).with('ext/uploads/events/?action=listAttachments&sectionid=1&eventid=2').and_return('files' => ['file1.txt', 'file2.txt'])
        Osm::Event.get_for_section(api: $api, section: 1)
        expect($api).not_to receive(:post_query)
        events = Osm::Event.get_list(api: $api, section: 1)
        expect(events.map{ |e| e[:id]}).to eq([2])
      end

    end # describe get events list for section


    it 'Get event' do
      expect($api).to receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(@event_body)
      event = Osm::Event.get(api: $api, section: 1, id: 2)
      expect(event).not_to be_nil
      expect(event.id).to eq(2)
    end

    describe 'Tells if there are spaces' do

      it 'No limit' do
        expect($api).not_to receive(:post_query)
        event = Osm::Event.new(attendance_limit: 0, id: 1, section_id: 2)
        expect(event.spaces?($api)).to eq(true)
        expect(event.spaces($api)).to be_nil
      end

      it 'Under limit' do
        expect($api).to receive(:post_query).with('events.php?action=getEventAttendance&eventid=1&sectionid=2&termid=3').and_return(          'identifier' => 'scoutid',
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
          ])
        allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 3) }

        event = Osm::Event.new(attendance_limit: 2, id: 1, section_id: 2)
        expect(event.spaces?($api)).to eq(true)
        expect(event.spaces($api)).to eq(1)
      end

      it 'Over limit' do
        expect($api).to receive(:post_query).with('events.php?action=getEventAttendance&eventid=1&sectionid=2&termid=3').and_return(          'identifier' => 'scoutid',
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
          ])
        allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 3) }

        event = Osm::Event.new(attendance_limit: 2, id: 1, section_id: 2)
        expect(event.spaces?($api)).to eq(false)
        expect(event.spaces($api)).to eq(-1)
      end

      it 'At limit' do
        expect($api).to receive(:post_query).with('events.php?action=getEventAttendance&eventid=1&sectionid=2&termid=3').and_return(          'identifier' => 'scoutid',
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
          ])
        allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 3) }

        event = Osm::Event.new(attendance_limit: 2, id: 1, section_id: 2)
        expect(event.spaces?($api)).to eq(false)
        expect(event.spaces($api)).to eq(0)
      end

    end

    describe 'Create (succeded)' do

      it 'Normal' do
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

        allow(Osm::Event).to receive(:get_for_section) { [] }
        expect($api).to receive(:post_query).with('events.php?action=addEvent&sectionid=1', post_data: post_data).and_return('id' => 2)

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
          allow_booking: true
        )
        expect(event).not_to be_nil
        expect(event.id).to eq(2)
      end

      it 'TBC cost' do
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

        allow(Osm::Event).to receive(:get_for_section) { [] }
        expect($api).to receive(:post_query).with('events.php?action=addEvent&sectionid=1', post_data: post_data).and_return('id' => 2)

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
          allow_booking: true
        )
        expect(event).not_to be_nil
        expect(event.id).to eq(2)
      end

      describe 'With badges' do

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

          allow(Osm::Event).to receive(:get_for_section) { [] }
          expect($api).to receive(:post_query).with('events.php?action=addEvent&sectionid=1', post_data: post_data).and_return('id' => 2)

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
          expect($api).to receive(:post_query).with(@badge_path, post_data: post_data).and_return('status' => true)

          @attributes[:badges] = [Osm::Event::BadgeLink.new(
            badge_type: :activity,
            badge_section: :beavers,
            requirement_label: '',
            data: '',
            badge_name: 'Test badge',
            badge_id: 3,
            badge_version: 2,
            requirement_id: 1
          )]
          event = Osm::Event.create(api: $api, **@attributes)
          expect(event).not_to be_nil
          expect(event.id).to eq(2)
        end

        it 'Add a hikes column' do
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
          expect($api).to receive(:post_query).with(@badge_path, post_data: post_data).and_return('status' => true)

          @attributes[:badges] = [Osm::Event::BadgeLink.new(
            badge_type: :staged,
            badge_section: :beavers,
            requirement_label: 'Label for added column',
            data: '1',
            badge_name: 'Test badge',
            badge_id: 3,
            badge_version: 2
          )]
          event = Osm::Event.create(api: $api, **@attributes)
          expect(event).not_to be_nil
          expect(event.id).to eq(2)
        end

        it 'Existing nights away column' do
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
          expect($api).to receive(:post_query).with(@badge_path, post_data: post_data).and_return('status' => true)

          @attributes[:badges] = [Osm::Event::BadgeLink.new(
            badge_type: :staged,
            badge_section: :beavers,
            requirement_label: '',
            data: '2',
            badge_name: 'Test badge',
            badge_id: 3,
            badge_version: 2,
            requirement_id: 4
          )]
          event = Osm::Event.create(api: $api, **@attributes)
          expect(event).not_to be_nil
          expect(event.id).to eq(2)
        end

      end

    end

    it 'Create (failed)' do
      allow(Osm::Event).to receive(:get_for_section) { [] }
      expect($api).to receive(:post_query).and_return({})

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
        reminders: true
      )
      expect(event).to be_nil
    end


    describe 'Update (succeded)' do

      it 'Normal' do
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

        expect($api).to receive(:post_query).with('events.php?action=addEvent&sectionid=1', post_data: post_data).and_return('id' => 2)
        expect($api).to receive(:post_query).with('events.php?action=saveNotepad&sectionid=1', post_data: { 'eventid'=>2, 'notepad'=>'notepad' }).and_return({})
        expect($api).to receive(:post_query).with('events.php?action=saveNotepad&sectionid=1', post_data: { 'eventid'=>2, 'pnnotepad'=>'public notepad' }).and_return({})

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
          allow_booking: true
        )
        event.name = 'Test event'
        event.notepad = 'notepad'
        event.public_notepad = 'public notepad'
        expect(event.update($api)).to eq(true)
      end

      it 'TBC cost' do
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

        expect($api).to receive(:post_query).with('events.php?action=addEvent&sectionid=1', post_data: post_data).and_return('id' => 2)

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
          allow_booking: true
        )
        event.cost = 'TBC'
        expect(event.update($api)).to eq(true)
      end

      describe 'Badge links' do

        before :each do
          @event = Osm::Event.new(            id: 2,
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
              requirement_id: 4
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
            allow_booking: true)
        end

        it 'Added' do
          badge = Osm::Event::BadgeLink.new(
            badge_type: :activity,
            badge_section: :scouts,
            requirement_label: 'A: Draw',
            data: 'Yes',
            badge_name: 'Artist',
            badge_id: 3,
            badge_version: 2,
            requirement_id: 6
          )
          expect(@event).to receive(:add_badge_link).with(api: $api, link: badge) { true }

          @event.badges.push(badge)
          expect(@event.update($api)).to eq(true)
        end

        it 'Removed' do
          post_data = {
            'section' => :scouts,
            'sectionid' => 1,
            'type' => 'event',
            'id' => 2,
            'badge_id' => 3,
            'badge_version' => 2,
            'column_id' => 4,
          }
          expect($api).to receive(:post_query).with('ext/badges/records/index.php?action=deleteBadgeLink&sectionid=1', post_data: post_data).and_return('status' => true)

          @event.badges = []
          expect(@event.update($api)).to eq(true)
        end

      end

    end

    it 'Update (failed)' do
      expect($api).to receive(:post_query).exactly(1).times.and_return({})

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
      expect(event.update($api)).to eq(false)
    end


    it 'Delete (succeded)' do
      expect($api).to receive(:post_query).with('events.php?action=deleteEvent&sectionid=1&eventid=2').and_return('ok' => true)

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
      expect(event.delete($api)).to eq(true)
    end

    it 'Delete (failed)' do
      expect($api).to receive(:post_query).with('events.php?action=deleteEvent&sectionid=1&eventid=2').and_return('ok' => false)

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
      expect(event.delete($api)).to eq(false)
    end


    it 'Get attendance' do
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

      expect($api).to receive(:post_query).with('events.php?action=getEventAttendance&eventid=2&sectionid=1&termid=3').and_return(attendance_body)

      event = Osm::Event.new(id: 2, section_id: 1)
      attendance = event.get_attendance(api: $api, term: 3)
      expect(attendance.is_a?(Array)).to eq(true)
      ea = attendance[0]
      expect(ea.member_id).to eq(1)
      expect(ea.grouping_id).to eq(2)
      expect(ea.first_name).to eq('First')
      expect(ea.last_name).to eq('Last')
      expect(ea.date_of_birth).to eq(Date.new(1980, 1, 2))
      expect(ea.attending).to eq(:yes)
      expect(ea.fields).to eq(        1 => 'a')
      expect(ea.payments).to eq(        1 => '')
      expect(ea.row).to eq(0)
    end

    it 'Get attendance (no items)' do
      attendance_body = {
      	'identifier' => 'scoutid',
	      'eventid' => '2',
      }

      expect($api).to receive(:post_query).with('events.php?action=getEventAttendance&eventid=2&sectionid=1&termid=3').and_return(attendance_body)

      event = Osm::Event.new(id: 2, section_id: 1)
      attendance = event.get_attendance(api: $api, term: 3)
      expect(attendance).to eq([])
    end

    it 'Add column (succeded)' do
      post_data = {
        'columnName' => 'Test name',
        'parentLabel' => 'Test label',
        'parentRequire' => 1
      }
      body = {
        'eventid' => '2',
        'config' => '[{"id":"f_1","name":"Test name","pL":"Test label"}]'
      }
      expect($api).to receive(:post_query).with('events.php?action=addColumn&sectionid=1&eventid=2', post_data: post_data).and_return(body)

      event = Osm::Event.new(id: 2, section_id: 1)
      expect(event).not_to be_nil
      expect(event.add_column(api: $api, name: 'Test name', label: 'Test label', required: true)).to eq(true)
      column = event.columns[0]
      expect(column.id).to eq('f_1')
      expect(column.name).to eq('Test name')
      expect(column.label).to eq('Test label')
    end

    it 'Add column (failed)' do
      expect($api).to receive(:post_query).and_return('config' => '[]')

      event = Osm::Event.new(id: 2, section_id: 1)
      expect(event).not_to be_nil
      expect(event.add_column(api: $api, name: 'Test name', label: 'Test label')).to eq(false)
    end

  end # describe using the OSM API


  describe 'API Strangeness' do

    it 'Handles a non existant array when no events' do
      data = { 'identifier' => 'eventid', 'label' => 'name' }
      expect($api).to receive(:post_query).with('events.php?action=getEvents&sectionid=1&showArchived=true').and_return(data)
      events = expect(Osm::Event.get_for_section(api: $api, section: 1)).to eq([])
    end

    it 'Handles missing config from OSM' do
      events_body = { 'identifier' => 'eventid', 'label' => 'name', 'items' => [{ 'eventid'=>'2','name'=>'An Event','startdate'=>'2001-02-03','enddate'=>'2001-02-05','starttime'=>'00:00:00','endtime'=>'12:00:00','cost'=>'0.00','location'=>'Somewhere','notes'=>'Notes','sectionid'=>1,'googlecalendar'=>nil,'archived'=>'0','confdate'=>nil,'allowchanges'=>'1','disablereminders'=>'1','attendancelimit'=>'3','limitincludesleaders'=>'1' }] }
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

      expect($api).to receive(:post_query).with('events.php?action=getEvent&sectionid=1&eventid=2').and_return(event_body)

      allow(Osm::Model).to receive(:get_user_permissions) { { events: [:read, :write] } }

      event = Osm::Event.get(api: $api, section: 1, id: 2)
      expect(event).not_to be_nil
      expect(event.id).to eq(2)
      expect(event.columns).to eq([])
    end

  end # describe API strangeness

end
