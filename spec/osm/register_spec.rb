describe Osm::Register do

  describe 'Using the API' do

    it 'Fetch the register structure for a section' do
      data = [
        { 'rows' => [{ 'name'=>'First name','field'=>'firstname','width'=>'100px' },{ 'name'=>'Last name','field'=>'lastname','width'=>'100px' },{ 'name'=>'Total','field'=>'total','width'=>'60px' }],'noscroll'=>true },
        { 'rows' => [{ 'field'=>'field1','name'=>'name1','tooltip'=>'tooltip1' }] }
      ]
      expect($api).to receive(:post_query).with('users.php?action=registerStructure&sectionid=1&termid=2'){ data }

      register_structure = Osm::Register.get_structure(api: $api, section: 1, term: 2)
      expect(register_structure.is_a?(Array)).to eq(true)
      expect(register_structure.size).to eq(1)
      expect(register_structure[0].id).to eq('field1')
      expect(register_structure[0].name).to eq('name1')
      expect(register_structure[0].tooltip).to eq('tooltip1')
    end

    it 'Fetch the register data for a section' do
      data = {
        'identifier' => 'scoutid',
        'label' => 'name',
        'items' => [
          {
            'total' => 4,
            '2000-01-01' => 'Yes',
            '2000-01-02' => 'No',
            'scoutid' => '2',
            'firstname' => 'First',
            'lastname' => 'Last',
            'patrolid' => '3'
          }
        ]
      }
      expect($api).to receive(:post_query).with('users.php?action=register&sectionid=1&termid=2') { data }
      allow(Osm::Register).to receive(:get_structure) { [
        Osm::Register::Field.new(id: '2000-01-01', name: 'Name', tooltip: 'Tooltip'),
        Osm::Register::Field.new(id: '2000-01-02', name: 'Name', tooltip: 'Tooltip'),
        Osm::Register::Field.new(id: '2000-01-03', name: 'Name', tooltip: 'Tooltip'),
      ] }

      register = Osm::Register.get_attendance(api: $api, section: 1, term: 2)
      expect(register.is_a?(Array)).to eq(true)
      expect(register.size).to eq(1)
      reg = register[0]
      expect(reg.attendance).to eq(        Date.new(2000, 1, 1) => :yes,
        Date.new(2000, 1, 2) => :advised_absent,
        Date.new(2000, 1, 3) => :unadvised_absent)
      expect(reg.first_name).to eq('First')
      expect(reg.last_name).to eq('Last')
      expect(reg.grouping_id).to eq(3)
      expect(reg.member_id).to eq(2)
      expect(reg.total).to eq(4)
      expect(reg.section_id).to eq(1)
      expect(reg.valid?).to eq(true)
    end

    it 'Update register attendance' do
      post_data = {
        'scouts' => '["3"]',
        'selectedDate' => '2000-01-02',
        'present' => 'Yes',
        'section' => :cubs,
        'sectionid' => 1,
        'completedBadges' => '[{"a":"A"},{"b":"B"}]'
      }
      expect($api).to receive(:post_query).with('users.php?action=registerUpdate&sectionid=1&termid=2', post_data: post_data){ [] }

      expect(Osm::Register.update_attendance(
        api: $api,
        section: Osm::Section.new(id: 1, type: :cubs),
        term: 2,
        date: Date.new(2000, 1, 2),
        attendance: :yes,
        members: 3,
        completed_badge_requirements: [{ 'a'=>'A' }, { 'b'=>'B' }]
      )).to eq(true)
    end

    it 'Handles the total row' do
      data = {
        'identifier' => 'scoutid',
        'label' => 'name',
        'items' => [
          {
            'total' => 1,
            'scoutid' => '2',
            'firstname' => 'First',
            'lastname' => 'Last',
            'patrolid' => '3'
          },{
            'total' => 119,
            '2000-01-01' => 8,
            'scoutid' => -1,
            'firstname' => 'TOTAL',
            'lastname' => '',
            'patrolid' => 0
          }
        ]
      }
      expect($api).to receive(:post_query).with('users.php?action=register&sectionid=1&termid=2'){ data }
      allow(Osm::Register).to receive(:get_structure) { [] }

      register = Osm::Register.get_attendance(api: $api, section: 1, term: 2)
      expect(register.is_a?(Array)).to eq(true)
      expect(register.size).to eq(1)
      reg = register[0]
      expect(reg.first_name).to eq('First')
      expect(reg.last_name).to eq('Last')
    end

    it 'Handles no data getting structure' do
      expect($api).to receive(:post_query).with('users.php?action=registerStructure&sectionid=1&termid=2') { nil }
      register_structure = Osm::Register.get_structure(api: $api, section: 1, term: 2)
      expect(register_structure.is_a?(Array)).to eq(true)
      expect(register_structure.size).to eq(0)
    end

  end

end
