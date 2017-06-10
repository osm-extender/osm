describe Osm::Event::Attendance do

  it 'Create' do
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
    expect(ea.member_id).to eq(1)
    expect(ea.grouping_id).to eq(2)
    expect(ea.fields).to eq({})
    expect(ea.payments).to eq({})
    expect(ea.row).to eq(3)
    expect(ea.first_name).to eq('First')
    expect(ea.last_name).to eq('Last')
    expect(ea.date_of_birth).to eq(Date.new(2000, 1, 2))
    expect(ea.attending).to eq(:yes)
    expect(ea.valid?).to eq(true)
  end

  it 'Sorts by event ID then row' do
    ea1 = Osm::Event::Attendance.new(event: Osm::Event.new(id: 1), row: 1)
    ea2 = Osm::Event::Attendance.new(event: Osm::Event.new(id: 2), row: 1)
    ea3 = Osm::Event::Attendance.new(event: Osm::Event.new(id: 2), row: 2)
    event_attendances = [ea3, ea2, ea1]

    expect(event_attendances.sort).to eq([ea1, ea2, ea3])
  end


  describe 'Using to OSM API' do

    it 'Update attendance (succeded)' do
      ea = Osm::Event::Attendance.new(row: 0, member_id: 4, fields: { 1 => 'old value', 2 => 'another old value' }, event: Osm::Event.new(id: 2, :section_id => 1))

      ea.fields[1] = 'value'
      expect($api).to receive(:post_query).with(
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
      expect($api).to receive(:post_query).with(
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
      expect($api).to receive(:post_query).with(
        'events.php?action=updateScout',
        post_data: {
          'scoutid' => 4,
          'column' => 'payment',
          'value' => 'Automatic',
          'sectionid' => 1,
          'row' => 0,
          'eventid' => 2,
        }).and_return({})

      expect(ea.update($api)).to eq(true)
    end # it update attendance (success)

    it 'Get audit trail' do
      data = [
      	{ 'date' => '10/06/2013 19:17','updatedby' => 'My.SCOUT','type' => 'detail','desc' => "Set 'Test' to 'Test data'" },
      	{ 'date' => '10/06/2013 19:16','updatedby' => 'My.SCOUT','type' => 'attendance','desc' => 'Attendance: Yes' },
	      { 'date' => '10/06/2013 19:15','updatedby' => 'A Leader ','type' => 'attendance','desc' => 'Attendance: Reserved' },
	      { 'date' => '10/06/2013 19:14','updatedby' => 'A Leader ','type' => 'attendance','desc' => 'Attendance: No' },
	      { 'date' => '10/06/2013 19:13','updatedby' => 'A Leader ','type' => 'attendance','desc' => 'Attendance: Yes' },
	      { 'date' => '10/06/2013 19:12','updatedby' => 'A Leader ','type' => 'attendance','desc' => 'Attendance: Invited' },
	      { 'date' => '10/06/2013 19:11','updatedby' => 'A Leader ','type' => 'attendance','desc' => 'Attendance: Show in My.SCOUT' },
      ]

      expect($api).to receive(:post_query).with('events.php?action=getEventAudit&sectionid=1&scoutid=2&eventid=3').and_return(data)

      ea = Osm::Event::Attendance.new(
        event: Osm::Event.new(id: 3, section_id: 1),
        member_id: 2
      )
      expect(ea.get_audit_trail($api)).to eq([
        { event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 17), by: 'My.SCOUT', :type => :detail, :description => "Set 'Test' to 'Test data'", :label => 'Test', :value => 'Test data' },
        { event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 16), by: 'My.SCOUT', :type => :attendance, :description => 'Attendance: Yes', :attendance => :yes },
        { event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 15), by: 'A Leader', :type => :attendance, :description => 'Attendance: Reserved', :attendance => :reserved },
        { event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 14), by: 'A Leader', :type => :attendance, :description => 'Attendance: No', :attendance => :no },
        { event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 13), by: 'A Leader', :type => :attendance, :description => 'Attendance: Yes', :attendance => :yes },
        { event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 12), by: 'A Leader', :type => :attendance, :description => 'Attendance: Invited', :attendance => :invited },
        { event_attendance: ea, event_id: 3, member_id: 2, at: DateTime.new(2013, 6, 10, 19, 11), by: 'A Leader', :type => :attendance, :description => 'Attendance: Show in My.SCOUT', :attendance => :shown },
      ])
    end

  end # describe using to OSM API

end
