describe OSM::Grouping do

  it 'Sorts by section_id then name' do
    g1 = OSM::Grouping.new(section_id: 1, name: 'a')
    g2 = OSM::Grouping.new(section_id: 2, name: 'a')
    g3 = OSM::Grouping.new(section_id: 2, name: 'b')

    data = [g3, g1, g2]
    expect(data.sort).to eq([g1, g2, g3])
  end

  describe 'Using the API' do

    it 'Get for section' do
      data = { 'patrols' => [{
        'patrolid' => 1,
        'name' => 'Patrol Name',
        'active' => 1,
        'points' => '3'
      }] }
      expect($api).to receive(:post_query).with('users.php?action=getPatrols&sectionid=2').and_return(data)

      patrols = OSM::Grouping.get_for_section(api: $api, section: 2)
      expect(patrols.size).to eq(1)
      patrol = patrols[0]
      expect(patrol.id).to eq(1)
      expect(patrol.section_id).to eq(2)
      expect(patrol.name).to eq('Patrol Name')
      expect(patrol.active).to eq(true)
      expect(patrol.points).to eq(3)
      expect(patrol.valid?).to eq(true)
    end

    it 'Handles no data' do
      expect($api).to receive(:post_query).with('users.php?action=getPatrols&sectionid=2').and_return(nil)
      patrols = OSM::Grouping.get_for_section(api: $api, section: 2)
      expect(patrols.size).to eq(0)
    end


    it 'Update in OSM (succeded)' do
      grouping = OSM::Grouping.new(
        id: 1,
        section_id: 2,
        active: true,
        points: 3
      )
      grouping.name = 'Grouping'

      post_data = {
        'patrolid' => grouping.id,
        'name' => grouping.name,
        'active' => grouping.active
      }
      expect($api).to receive(:post_query).with('users.php?action=editPatrol&sectionid=2', post_data: post_data).and_return(nil)

      expect(grouping.update($api)).to eq(true)
    end

    it 'Update points in OSM (succeded)' do
      grouping = OSM::Grouping.new(
        id: 1,
        section_id: 2,
        active: true,
        name: 'Grouping'
      )
      grouping.points = 3

      post_data = {
        'patrolid' => grouping.id,
        'points' => grouping.points
      }
      expect($api).to receive(:post_query).with('users.php?action=updatePatrolPoints&sectionid=2', post_data: post_data).and_return({})

      expect(grouping.update($api)).to eq(true)
    end

    it 'Update in OSM (failed)' do
      grouping = OSM::Grouping.new(
        id: 1,
        section_id: 2,
        points: 3
      )
      grouping.name = 'Grouping'
      grouping.active = true

      expect($api).to receive(:post_query).and_return('done' => false)

      expect(grouping.update($api)).to eq(false)
    end

    it 'Update points in OSM (failed)' do
      grouping = OSM::Grouping.new(
        id: 1,
        section_id: 2,
        name: 'Name',
        active: true
      )
      grouping.points = 3

      expect($api).to receive(:post_query).and_return('done' => false)

      expect(grouping.update($api)).to eq(false)
    end

  end

end
