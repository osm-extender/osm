describe OSM::Activity do

  it 'Get OSM link' do
    activity = OSM::Activity.new(
      id: 1,
      running_time: 10,
      title: 'Title',
      description: 'Description',
      resources: 'Resources',
      instructions: 'Instructions',
      location: :indoors
    )
    expect(activity.osm_link).to eq('https://www.onlinescoutmanager.co.uk/?l=p1')
  end

  it 'Sorts by id then version' do
    expect(OSM::Activity.new.send(:sort_by)).to eq(['id', 'version'])
  end


  describe 'Using The API' do

    it 'Get One' do
      body = {
          'details' => {
          'activityid' => '1',
          'version' => '0',
          'groupid' => '2',
          'userid' => '3',
          'title' => 'Activity Name',
          'description' => 'Description',
          'resources' => 'Resources',
          'instructions' => 'Instructions',
          'runningtime' => '15',
          'location' => 'indoors',
          'shared' => '0',
          'rating' => '4',
          'facebook' => ''
        },
        'editable' => true,
        'deletable' => false,
        'used' => 3,
        'versions' => [
          {
            'value' => '0',
            'userid' => '1',
            'firstname' => 'Alice',
            'label' => 'Current version - Alice',
            'selected' => 'selected'
          }
        ],
        'sections' => ['beavers', 'cubs'],
        'tags' => ['Tag 1', 'Tag2'],
        'files' => [
          {
            'fileid' => '6',
            'activityid' => '1',
            'filename' => 'File Name',
            'name' => 'Name'
          }
        ],
        'badges' => [
          {
            'badge' => 'activity_firesafety',
            'badgeLongName' => 'Fire Safety',
            'badge_id' => '181',
            'badge_version' => '0',
            'badgetype' => 'activity',
            'badgetypeLongName' => 'Activity',
            'column_id' => '93384',
            'columnname' => 'b_01',
            'columnnameLongName' => 'B: Fire drill',
            'data' => 'Yes',
            'section' => 'cubs',
            'sectionLongName' => 'Cubs'
          }
        ]
      }
      expect($api).to receive(:post_query).with('programme.php?action=getActivity&id=1').and_return(body)

      activity = OSM::Activity.get(api: $api, id: 1)

      expect(activity.id).to eq(1)
      expect(activity.version).to eq(0)
      expect(activity.group_id).to eq(2)
      expect(activity.user_id).to eq(3)
      expect(activity.title).to eq('Activity Name')
      expect(activity.description).to eq('Description')
      expect(activity.resources).to eq('Resources')
      expect(activity.instructions).to eq('Instructions')
      expect(activity.running_time).to eq(15)
      expect(activity.location).to eq(:indoors)
      expect(activity.shared).to eq(0)
      expect(activity.rating).to eq(4)
      expect(activity.editable).to eq(true)
      expect(activity.deletable).to eq(false)
      expect(activity.used).to eq(3)
      expect(activity.versions[0].version).to eq(0)
      expect(activity.versions[0].created_by).to eq(1)
      expect(activity.versions[0].created_by_name).to eq('Alice')
      expect(activity.versions[0].label).to eq('Current version - Alice')
      expect(activity.sections).to eq([:beavers, :cubs])
      expect(activity.tags).to eq(['Tag 1', 'Tag2'])
      expect(activity.files[0].id).to eq(6)
      expect(activity.files[0].activity_id).to eq(1)
      expect(activity.files[0].file_name).to eq('File Name')
      expect(activity.files[0].name).to eq('Name')
      expect(activity.badges[0].badge_type).to eq(:activity)
      expect(activity.badges[0].badge_section).to eq(:cubs)
      expect(activity.badges[0].badge_name).to eq('Fire Safety')
      expect(activity.badges[0].badge_id).to eq(181)
      expect(activity.badges[0].badge_version).to eq(0)
      expect(activity.badges[0].requirement_id).to eq(93384)
      expect(activity.badges[0].requirement_label).to eq('B: Fire drill')
      expect(activity.badges[0].data).to eq('Yes')
      expect(activity.valid?).to eq(true)
    end


    it 'Add activity to programme (succeded)' do
      post_data = {
        'meetingdate' => '2000-01-02',
        'sectionid' => 1,
        'activityid' => 2,
        'notes' => 'Notes'
      }
      expect($api).to receive(:post_query).with('programme.php?action=addActivityToProgramme', post_data: post_data).and_return('result' => 0)

      activity = OSM::Activity.new(id: 2)
      expect(activity.add_to_programme(api: $api, section: 1, date: Date.new(2000, 1, 2), notes: 'Notes')).to eq(true)
    end

    it 'Add activity to programme (failed)' do
      post_data = {
        'meetingdate' => '2000-01-02',
        'sectionid' => 1,
        'activityid' => 2,
        'notes' => 'Notes'
      }
      expect($api).to receive(:post_query).with('programme.php?action=addActivityToProgramme', post_data: post_data).and_return('result' => 1)

      activity = OSM::Activity.new(id: 2)
      expect(activity.add_to_programme(api: $api, section: 1, date: Date.new(2000, 1, 2), notes: 'Notes')).to eq(false)
    end


    it 'Update activity in OSM (succeded)' do
      post_data = {
        'title' => 'title',
        'description' => 'description',
        'resources' => 'resources',
        'instructions' => 'instructions',
        'id' => 2,
        'files' => '3,4',
        'time' => '5',
        'location' => :indoors,
        'sections' => '["beavers","cubs"]',
        'tags' => '["tag1","tag2"]',
        'links' => '[{"badge_id":"181","badge_version":"0","column_id":"93384","badge":null,"badgeLongName":"Badge name","columnname":null,"columnnameLongName":"l","data":"","section":"beavers","sectionLongName":null,"sections":["beavers","cubs"],"badgetype":"activity","badgetypeLongName":null}]',
        'shared' => 0,
        'sectionid' => 1,
        'secretEdit' => true
      }

      expect($api).to receive(:post_query).with('programme.php?action=update', post_data: post_data).and_return('result' => true)

      activity = OSM::Activity.new(
        id: 2,
        title: 'title',
        description: 'description',
        resources: 'resources',
        instructions: 'instructions',
        files: [OSM::Activity::File.new(id: 3, activity_id: 2, file_name: 'fn', name: 'n'), OSM::Activity::File.new(:id => 4, :activity_id => 2, :file_name => 'fn2', :name => 'n2')],
        running_time: 5,
        location: :indoors,
        sections: [:beavers, :cubs],
        tags: ['tag1', 'tag2'],
        badges: [OSM::Activity::Badge.new(
          badge_type: :activity,
          badge_section: :beavers,
          requirement_label: 'l',
          data: '',
          badge_name: 'Badge name',
          badge_id: 181,
          badge_version: 0,
          requirement_id: 93384
        )],
        shared: 0,
        section_id: 1
      )
      expect(activity.update(api: $api, section: 1, secret_update: true)).to eq(true)
    end

    it 'Update activity in OSM (failed)' do
      activity = OSM::Activity.new(
        id: 2,
        title: 'title',
        description: 'description',
        resources: 'resources',
        instructions: 'instructions',
        location: :indoors,
        running_time: 0
      )
      expect($api).to receive(:post_query).and_return('result' => false)
      expect(activity.update(api: $api, section: 1, secret_update: true)).to eq(false)
    end

  end

end
