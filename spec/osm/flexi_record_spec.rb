describe Osm::FlexiRecord do

  it 'Create' do
    fr = Osm::FlexiRecord.new(
      id: 1,
      section_id: 2,
      name: 'name'
    )
    expect(fr.id).to eq(1)
    expect(fr.section_id).to eq(2)
    expect(fr.name).to eq('name')
    expect(fr.valid?).to eq(true)
  end

  it 'Sorts by section ID then name' do
    fr1 = Osm::FlexiRecord.new(section_id: 1, name: 'A')
    fr2 = Osm::FlexiRecord.new(section_id: 2, name: 'B')
    fr3 = Osm::FlexiRecord.new(section_id: 2, name: 'C')
    records = [fr2, fr1, fr3]

    expect(records.sort).to eq([fr1, fr2, fr3])
  end


  describe 'Using the API' do

    before :each do
      @flexi_record = Osm::FlexiRecord.new(section_id: 1, id: 2, name: 'A Flexi Record')
    end

    it 'Fetch Fields' do
      data = {
        'extraid' => '2',
        'sectionid' => '1',
        'name' => 'A Flexi Record',
        'config' => '[{"id":"f_1","name":"Field 1","width":"150"},{"id":"f_2","name":"Field 2","width":"150"}]',
        'total' => 'none',
        'extrafields' => '[]',
        'structure' => [
          {
            'rows' => [
              { 'name' => 'First name','field' => 'firstname','width' => '150px' },
              { 'name' => 'Last name','field' => 'lastname','width' => '150px' }
            ],
            'noscroll' => true
          },
          { 'rows' => [
            { 'name' => 'Field 1','field' => 'f_1','width' => '150px','editable' => true },
            { 'name' => 'Filed 2','field' => 'f_2','width' => '150px','editable' => true }
          ] }
        ]
      }
      expect($api).to receive(:post_query).with('extras.php?action=getExtra&sectionid=1&extraid=2').and_return(data)

      fields = @flexi_record.get_columns($api)
      expect(fields.is_a?(Array)).to eq(true)
      expect(fields[0].valid?).to eq(true)
      expect(fields[0].id).to eq('firstname')
      expect(fields[1].id).to eq('lastname')
      expect(fields[2].id).to eq('f_1')
      expect(fields[3].id).to eq('f_2')
    end

    it 'Add field (success)' do
      post_data = {
        'columnName' => 'name'
      }

      data = {
        'extraid' => '2',
        'sectionid' => '1',
        'name' => 'A Flexi Record',
        'config' => '[{"id":"f_1","name":"name","width":"150"}]',
        'total' => 'none',
        'extrafields' => '[]',
        'structure' => [
          {
            'rows' => [
              { 'name' => 'First name','field' => 'firstname','width' => '150px' },
              { 'name' => 'Last name','field' => 'lastname','width' => '150px' }
            ],
            'noscroll' => true
          },
          { 'rows' => [
            { 'name' => 'name','field' => 'f_1','width' => '150px','editable' => true }
          ] }
        ]
      }
      expect($api).to receive(:post_query).with('extras.php?action=addColumn&sectionid=1&extraid=2', post_data: post_data).and_return(data)

      expect(@flexi_record.add_column(api: $api, name: 'name')).to eq(true)
    end

    it 'Add field (failure)' do
      data = {
        'extraid' => '2',
        'sectionid' => '1',
        'name' => 'A Flexi Record',
        'config' => '[]',
        'total' => 'none',
        'extrafields' => '[]',
        'structure' => [
          {
            'rows' => [
              { 'name' => 'First name','field' => 'firstname','width' => '150px' },
              { 'name' => 'Last name','field' => 'lastname','width' => '150px' }
            ],
            'noscroll' => true
          },
          { 'rows' => [
          ] }
        ]
      }
      expect($api).to receive(:post_query).and_return(data)

      expect(@flexi_record.add_column(api: $api, name: 'name')).to eq(false)
    end

    it 'Fetch Data' do
      data = {
        'identifier' => 'scoutid',
        'label' => 'name',
        'items' => [{
          'scoutid' => '1',
          'firstname' => 'First',
          'lastname' => 'Last',
          'dob' => '',
          'patrolid' => '2',
          'total' => '',
          'completed' => '',
          'f_1' => 'A',
          'f_2' => 'B',
          'age' => '',
          'patrol' => 'Green'
        }]
      }
      expect($api).to receive(:post_query).with('extras.php?action=getExtraRecords&sectionid=1&extraid=2&termid=3&section=cubs').and_return(data)
      allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 1, type: :cubs) }

      records = @flexi_record.get_data(api: $api, term: 3)
      expect(records.is_a?(Array)).to eq(true)
      expect(records.size).to eq(1)
      record = records[0]
      expect(record.member_id).to eq(1)
      expect(record.grouping_id).to eq(2)
      expect(record.fields).to eq(        'firstname' => 'First',
        'lastname' => 'Last',
        'dob' => nil,
        'total' => nil,
        'completed' => nil,
        'age' => nil,
        'f_1' => 'A',
        'f_2' => 'B')
      expect(record.valid?).to eq(true)
    end

    it 'Handles the total row' do
      data = {
        'identifier' => 'scoutid',
        'label' => 'name',
        'items' => [{
          'scoutid' => '-1',
          'firstname' => 'TOTAL',
          'lastname' => '',
          'dob' => '',
          'patrolid' => '-1',
          'total' => 100,
          'completed' => 0,
          'f_1' => 25,
          'f_2' => 75,
          'age' => '',
          'patrol' => ''
        },{
          'scoutid' => '1',
          'firstname' => 'First',
          'lastname' => 'Last',
          'dob' => '',
          'patrolid' => '2',
          'total' => '',
          'completed' => '',
          'f_1' => 'A',
          'f_2' => 'B',
          'age' => '',
          'patrol' => 'Green'
        }]
      }
      expect($api).to receive(:post_query).with('extras.php?action=getExtraRecords&sectionid=1&extraid=2&termid=3&section=cubs').and_return(data)
      allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 1, type: :cubs) }

      records = @flexi_record.get_data(api: $api, term: 3)
      expect(records.is_a?(Array)).to eq(true)
      expect(records.size).to eq(1)
      record = records[0]
      expect(record.member_id).to eq(1)
      expect(record.grouping_id).to eq(2)
      expect(record.fields['firstname']).to eq('First')
      expect(record.fields['lastname']).to eq('Last')
    end

  end

  describe 'API Strangeness' do

    it 'Calculated columns containing numbers not strings' do
      data = {
        'identifier' => 'scoutid',
        'label' => 'name',
        'items' => [{
          'scoutid' => '1',
          'firstname' => 'First',
          'lastname' => 'Last',
          'dob' => '',
          'patrolid' => '2',
          'total' => 3,
          'completed' => 4,
          'f_1' => 'A',
          'f_2' => 'B',
          'age' => '',
          'patrol' => 'Green'
        }]
      }
      expect($api).to receive(:post_query).with('extras.php?action=getExtraRecords&sectionid=1&extraid=2&termid=3&section=cubs').and_return(data)
      allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 1, type: :cubs) }

      flexi_record = Osm::FlexiRecord.new(section_id: 1, id: 2, name: 'A Flexi Record')
      records = flexi_record.get_data(api: $api, term: 3)
      record = records[0]
      expect(record.fields['total']).to eq(3)
      expect(record.fields['completed']).to eq(4)
    end

  end

end
