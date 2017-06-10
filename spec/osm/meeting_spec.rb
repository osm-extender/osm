describe Osm::Meeting do

  it 'Create' do
    e = Osm::Meeting.new(
      id: 1,
      section_id: 2,
      title: 'Meeting Name',
      notes_for_parents: 'Notes for parents',
      games: 'Games',
      pre_notes: 'Before',
      post_notes: 'After',
      leaders: 'Leaders',
      start_time: '19:00',
      finish_time: '21:00',
      date: Date.new(2000, 01, 02),
      activities: [],
      badge_links: []
    )

    expect(e.id).to eq(1)
    expect(e.section_id).to eq(2)
    expect(e.title).to eq('Meeting Name')
    expect(e.notes_for_parents).to eq('Notes for parents')
    expect(e.games).to eq('Games')
    expect(e.pre_notes).to eq('Before')
    expect(e.post_notes).to eq('After')
    expect(e.leaders).to eq('Leaders')
    expect(e.start_time).to eq('19:00')
    expect(e.finish_time).to eq('21:00')
    expect(e.date).to eq(Date.new(2000, 1, 2))
    expect(e.activities).to eq([])
    expect(e.badge_links).to eq([])
    expect(e.valid?).to eq(true)
  end

  it 'Sorts by Section ID, Meeting date, Start time and then Meeting ID' do
    meeting1 = Osm::Meeting.new(section_id: 1, id: 1, date: (Date.today - 1), start_time: '18:00')
    meeting2 = Osm::Meeting.new(section_id: 2, id: 1, date: (Date.today - 1), start_time: '18:00')
    meeting3 = Osm::Meeting.new(section_id: 2, id: 1, date: (Date.today + 1), start_time: '18:00')
    meeting4 = Osm::Meeting.new(section_id: 2, id: 1, date: (Date.today + 1), start_time: '19:00')
    meeting5 = Osm::Meeting.new(section_id: 2, id: 2, date: (Date.today + 1), start_time: '19:00')

    data = [meeting5, meeting3, meeting2, meeting4, meeting1]
    expect(data.sort).to eq([meeting1, meeting2, meeting3, meeting4, meeting5])
  end


  describe 'Using the API' do

    it "Fetch the term's programme for a section" do
      body = {
        'items' => [{'eveningid' => '5', 'sectionid' =>'3', 'title' => 'Weekly Meeting 1', 'notesforparents' => 'parents', 'games' => 'games', 'prenotes' => 'before', 'postnotes' => 'after', 'leaders' => 'leaders', 'meetingdate' => '2001-02-03', 'starttime' => '19:15:00', 'endtime' => '20:30:00', 'googlecalendar' => ''}],
        'activities' => {'5' => [
          {'activityid' => '6', 'title' => 'Activity 6', 'notes' => 'Some notes', 'eveningid' => '5'},
          {'activityid' => '7', 'title' => 'Activity 7', 'notes' => '', 'eveningid' => '5'}
        ]},
        'badgelinks' => {'5' => [{
          'badge' => 'artist',
          'badgeLongName' => 'Artist',
          'badge_id' => '180',
          'badge_version' => '0',
          'badgetype' => 'activity',
          'badgetypeLongName' => 'Activity',
          'column_id' => '1234',
          'columnname' => '1234',
          'columnnameLongName' => 'Guide Dogs',
          'data' => '',
          'label' => 'Disability Awareness Activity Guide dogs',
          'section' => 'cubs',
          'sectionLongName' => 'Cubs',
         }]},
      }
      expect($api).to receive(:post_query).with('programme.php?action=getProgramme&sectionid=3&termid=4').and_return(body)

      programme = Osm::Meeting.get_for_section(api: $api, section: 3, term: 4)
      expect(programme.size).to eq(1)
      meeting = programme[0]
      expect(meeting.is_a?(Osm::Meeting)).to eq(true)
      expect(meeting.id).to eq(5)
      expect(meeting.section_id).to eq(3)
      expect(meeting.title).to eq('Weekly Meeting 1')
      expect(meeting.notes_for_parents).to eq('parents')
      expect(meeting.games).to eq('games')
      expect(meeting.pre_notes).to eq('before')
      expect(meeting.post_notes).to eq('after')
      expect(meeting.leaders).to eq('leaders')
      expect(meeting.date).to eq(Date.new(2001, 2, 3))
      expect(meeting.start_time).to eq('19:15')
      expect(meeting.finish_time).to eq('20:30')
      expect(meeting.activities.size).to eq(2)
      activity = meeting.activities[0]
      expect(activity.activity_id).to eq(6)
      expect(activity.title).to eq('Activity 6')
      expect(activity.notes).to eq('Some notes')
      expect(meeting.badge_links.size).to eq(1)
      badge_link = meeting.badge_links[0]
      expect(badge_link.badge_type).to eq(:activity)
      expect(badge_link.badge_section).to eq(:cubs)
      expect(badge_link.badge_name).to eq('Artist')
      expect(badge_link.badge_id).to eq(180)
      expect(badge_link.badge_version).to eq(0)
      expect(badge_link.requirement_id).to eq(1234)
      expect(badge_link.requirement_label).to eq('Guide Dogs')
      expect(badge_link.data).to eq('')
    end

    it 'Fetch badge requirements for a meeting (from API)' do
      allow(Osm::Model).to receive('has_permission?').and_return(true)
      allow(Osm::Section).to receive(:get){ Osm::Section.new(id: 3, type: :cubs) }
      badges_body = [{'a'=>'a'},{'a'=>'A'}]
      expect($api).to receive(:post_query).with('users.php?action=getActivityRequirements&date=2000-01-02&sectionid=3&section=cubs').and_return(badges_body)

      meeting = Osm::Meeting.new(date: Date.new(2000, 1, 2), section_id: 3)
      expect(meeting.get_badge_requirements($api)).to eq(badges_body)
    end

    it 'Fetch badge requirements for a meeting (iterating through activities)' do
      allow(Osm::Model).to receive('has_permission?').with(api: $api, to: :write, on: :badge, section: 3, no_read_cache: false).and_return(false)
      allow(Osm::Section).to receive(:get){ Osm::Section.new(id: 3, type: :cubs) }
      allow(Osm::Activity).to receive(:get) { Osm::Activity.new(badges: [
        Osm::Activity::Badge.new(badge_type: :activity, badge_section: :beavers, requirement_label: 'label', data: 'data', badge_name: 'badge', badge_id: 2, badge_version: 0, requirement_id: 200)
      ]) }
  
      meeting = Osm::Meeting.new(
        id: 2,
        date: Date.new(2000, 1, 2),
        section_id: 3,
        activities: [Osm::Meeting::Activity.new(activity_id: 4)],
        badge_links: [
          Osm::Activity::Badge.new(badge_type: :activity, badge_section: :beavers, requirement_label: 'label 2', data: 'data 2', badge_name: 'badge 2', badge_id: 4, badge_version: 1, requirement_id: 400)
        ],
      )

      expect(meeting.get_badge_requirements($api)).to eq([
        {'badge'=>nil, 'badge_id'=>4, 'badge_version'=>1, 'column_id'=>400, 'badgeName'=>'badge 2', 'badgetype'=>:activity, 'columngroup'=>nil, 'columnname'=>nil, 'data'=>'data 2', 'eveningid'=>2, 'meetingdate'=>Date.new(2000, 1, 2), 'name'=>'label 2', 'section'=>:beavers, 'sectionid'=>3},
        {'badge'=>nil, 'badge_id'=>2, 'badge_version'=>0, 'column_id'=>200, 'badgeName'=>'badge', 'badgetype'=>:activity, 'columngroup'=>nil, 'columnname'=>nil, 'data'=>'data', 'eveningid'=>2, 'meetingdate'=>Date.new(2000, 1, 2), 'name'=>'label', 'section'=>:beavers, 'sectionid'=>3}
      ])
    end

    it 'Create a meeting (succeded)' do
      expect($api).to receive(:post_query).with('programme.php?action=addActivityToProgramme', post_data: {        'meetingdate' => '2000-01-02',
        'sectionid' => 1,
        'activityid' => -1,
        'start' => '2000-01-02',
        'starttime' => '11:11',
        'endtime' => '22:22',
        'title' => 'Title',
      }).and_return({'result'=>0})

      term = Osm::Term.new(id: 2)
      allow(Osm::Term).to receive(:get_for_section) { [term] }
      expect(Osm::Meeting).to receive(:cache_delete).with(api: $api, cache_key: ['programme', 1, 2]).and_return(true)

      expect(Osm::Meeting.create($api, **{
        section_id: 1,
        date: Date.new(2000, 1, 2),
        start_time: '11:11',
        finish_time: '22:22',
        title: 'Title',
      }).is_a?(Osm::Meeting)).to eq(true)
    end

    it 'Create a meeting (failed)' do
      allow(Osm::Term).to receive(:get_for_section) { [] }
      expect($api).to receive(:post_query).and_return([])
      expect(Osm::Meeting.create($api, **{
        section_id: 1,
        date: Date.new(2000, 1, 2),
        start_time: '11:11',
        finish_time: '22:22',
        title: 'Title',
      })).to be_nil
    end


    it 'Add activity to meeting (succeded)' do
      expect($api).to receive(:post_query).with('programme.php?action=addActivityToProgramme', post_data: {        'meetingdate' => '2000-01-02',
        'sectionid' => 1,
        'activityid' => 2,
        'notes' => 'Notes',
      }).and_return({'result'=>0})
      allow(Osm::Term).to receive(:get_for_section) { [] }

      activity = Osm::Activity.new(id: 2, title: 'Title')
      meeting = Osm::Meeting.new(section_id: 1, date: Date.new(2000, 1, 2))
      expect(meeting.add_activity(api: $api, activity: activity, notes: 'Notes')).to eq(true)
      expect(meeting.activities[0].activity_id).to eq(2)
    end

    it 'Add activity to meeting (failed)' do
      expect($api).to receive(:post_query).with('programme.php?action=addActivityToProgramme', post_data: {        'meetingdate' => '2000-01-02',
        'sectionid' => 1,
        'activityid' => 2,
        'notes' => 'Notes',
      }).and_return({'result'=>1})
      activity = Osm::Activity.new(id: 2, title: 'Title')
      meeting = Osm::Meeting.new(section_id: 1, date: Date.new(2000, 1, 2))
      expect(meeting.add_activity(api: $api, activity: activity, notes: 'Notes')).to eq(false)
    end


    it 'Update a meeting (succeded)' do
      expect($api).to receive(:post_query).with('programme.php?action=editEvening', post_data: {
        'eveningid' => 1, 'sectionid' => 2, 'meetingdate' => '2000-01-02', 'starttime' => nil,
        'endtime' => nil, 'title' => 'Unnamed meeting', 'notesforparents' =>'', 'prenotes' => '',
        'postnotes' => '', 'games' => '', 'leaders' => '',
        'activity' => '[{"activityid":3,"notes":"Some notes"}]',
        'badgelinks' => '[{"badge_id":"181","badge_version":"0","column_id":"93384","badge":null,"badgeLongName":"Badge name","columnname":null,"columnnameLongName":"l","data":"","section":"beavers","sectionLongName":null,"badgetype":"activity","badgetypeLongName":null}]',
      }).and_return({'result'=>0})
      allow(Osm::Term).to receive(:get_for_section) { [] }

      meeting = Osm::Meeting.new(
        id:1,
        section_id:2,
        date:Date.new(2000, 01, 02),
        activities: [Osm::Meeting::Activity.new(activity_id: 3, title: 'Activity Title', notes: 'Some notes')],
        badge_links: [Osm::Meeting::BadgeLink.new(
          badge_type: :activity,
          badge_section: :beavers,
          requirement_label: 'l',
          data: '',
          badge_name: 'Badge name',
          badge_id: 181,
          badge_version: 0,
          requirement_id: 93384,
        )]
      )
      expect(meeting.update($api)).to eq(true)
    end

    it 'Update a meeting (failed)' do
      expect($api).to receive(:post_query).with('programme.php?action=editEvening', post_data: {
        'eveningid' => 1, 'sectionid' => 2, 'meetingdate' => '2000-01-02', 'starttime' => nil,
        'endtime' => nil, 'title' => 'Unnamed meeting', 'notesforparents' =>'', 'prenotes' => '',
        'postnotes' => '', 'games' => '', 'leaders' => '', 'activity' => '[]', 'badgelinks' => '[]',
      }).and_return({'result'=>1})
      allow(Osm::Term).to receive(:get_for_section) { [] }

      meeting = Osm::Meeting.new(id:1, section_id:2, date:Date.new(2000, 01, 02))
      expect(meeting.update($api)).to eq(false)
    end

    it 'Update a meeting (invalid meeting)' do
      meeting = Osm::Meeting.new
      expect{ meeting.update($api) }.to raise_error(Osm::ObjectIsInvalid)
    end


    it 'Delete a meeting' do
      expect($api).to receive(:post_query).with('programme.php?action=deleteEvening&eveningid=1&sectionid=2').and_return(nil)
      allow(Osm::Term).to receive(:get_for_section) { [] }

      meeting = Osm::Meeting.new(id:1, section_id:2)
      expect(meeting.delete($api)).to eq(true)
    end

  end # Describe using API

  describe 'API Strangeness' do
    it 'Activity details is an Array [id, Hash]' do
      body = {
        'items' => [{'eveningid' => '5', 'sectionid' =>'3', 'title' => 'Weekly Meeting 1', 'notesforparents' => 'parents', 'games' => 'games', 'prenotes' => 'before', 'postnotes' => 'after', 'leaders' => 'leaders', 'meetingdate' => '2001-02-03', 'starttime' => '19:15:00', 'endtime' => '20:30:00', 'googlecalendar' => ''}],
        'activities' => {'5' => [
          ['6', {'activityid' => '6', 'title' => 'Activity 6', 'notes' => 'Some notes', 'eveningid' => '5'}],
        ]},
        'badgelinks' => {'5' => []},
      }
      expect($api).to receive(:post_query).with('programme.php?action=getProgramme&sectionid=3&termid=4').and_return(body)

      programme = Osm::Meeting.get_for_section(api: $api, section: 3, term: 4)
      expect(programme.size).to eq(1)
      meeting = programme[0]
      expect(meeting.activities.size).to eq(1)
      activity = meeting.activities[0]
      expect(activity.activity_id).to eq(6)
      expect(activity.title).to eq('Activity 6')
      expect(activity.notes).to eq('Some notes')
      expect(meeting.valid?).to eq(true)
    end
  end

end
