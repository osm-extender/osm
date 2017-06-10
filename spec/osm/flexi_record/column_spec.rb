describe Osm::FlexiRecord::Column do

  it 'Create' do
    field = Osm::FlexiRecord::Column.new(
      id: 'f_1',
      name: 'Field Name',
      editable: true,
      flexi_record: Osm::FlexiRecord.new(),
    )

    expect(field.id).to eq('f_1')
    expect(field.name).to eq('Field Name')
    expect(field.editable).to eq(true)
    expect(field.valid?).to eq(true)
  end

  it 'Sorts by flexirecord then id (system first then user)' do
    frc1 = Osm::FlexiRecord::Column.new(flexi_record: Osm::FlexiRecord.new(section_id: 1), id: 'f_1')
    frc2 = Osm::FlexiRecord::Column.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), id: 'a')
    frc3 = Osm::FlexiRecord::Column.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), id: 'b')
    frc4 = Osm::FlexiRecord::Column.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), id: 'f_1')
    frc5 = Osm::FlexiRecord::Column.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), id: 'f_2')

    # Compare section 1 > section 2
    expect(frc1 <=> frc2).to eq(-1)
    # Compare system field > system field
    expect(frc2 <=> frc3).to eq(-1)
    # Compare user field > user field
    expect(frc4 <=> frc5).to eq(-1)
    # Compare system field > user field
    expect(frc3 <=> frc4).to eq(-1)
    # Compare user field < system field
    expect(frc4 <=> frc3).to eq(1)

    columns = [frc3, frc2, frc1, frc5, frc4]
    expect(columns.sort).to eq([frc1, frc2, frc3, frc4, frc5])
  end


  describe 'Update' do

    before :each do
      @flexi_record = Osm::FlexiRecord.new(section_id: 1, id: 2, name: 'A Flexi Record')
    end

    it 'Success' do
      post_data = {
        'columnId' => 'f_1',
        'columnName' => 'name',
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
              { 'name' => 'Last name','field' => 'lastname','width' => '150px' },
            ],
            'noscroll' => true
          },
          { 'rows' => [
            { 'name' => 'name','field' => 'f_1','width' => '150px','editable' => true },
          ] }
        ]
      }
      expect($api).to receive(:post_query).with('extras.php?action=renameColumn&sectionid=1&extraid=2', post_data: post_data).and_return(data)

      col = Osm::FlexiRecord::Column.new(
        flexi_record: @flexi_record,
        id: 'f_1',
        name: 'name',
        editable: true
      )
      expect(col.update($api)).to eq(true)
    end

    it 'Failure' do
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
              { 'name' => 'Last name','field' => 'lastname','width' => '150px' },
            ],
            'noscroll' => true
          },
          { 'rows' => [
          ] }
        ]
      }
      expect($api).to receive(:post_query).and_return(data)

      col = Osm::FlexiRecord::Column.new(
        flexi_record: @flexi_record,
        id: 'f_1',
        name: 'name',
        editable: true
      )
      expect(col.update($api)).to eq(false)
    end

    it 'Uneditable' do
      col = Osm::FlexiRecord::Column.new(
        flexi_record: @flexi_record,
        id: 'f_1',
        name: 'name',
        editable: false
      )
      expect($api).not_to receive(:post_query)
      expect{ col.update($api) }.to raise_error(Osm::Forbidden)
    end

  end # desxribe update


  describe 'Delete' do

    before :each do
      @flexi_record = Osm::FlexiRecord.new(section_id: 1, id: 2, name: 'A Flexi Record')
    end

    it 'Success' do
      post_data = {
        'columnId' => 'f_1',
      }
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
              { 'name' => 'Last name','field' => 'lastname','width' => '150px' },
            ],
            'noscroll' => true
          },
          { 'rows' => [] }
        ]
      }
      expect($api).to receive(:post_query).with('extras.php?action=deleteColumn&sectionid=1&extraid=2', post_data: post_data).and_return(data)

      col = Osm::FlexiRecord::Column.new(
        flexi_record: @flexi_record,
        id: 'f_1',
        name: 'name',
        editable: true
      )
      expect(col.delete($api)).to eq(true)
    end

    it 'Failure' do
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
              { 'name' => 'Last name','field' => 'lastname','width' => '150px' },
            ],
            'noscroll' => true
          },
          { 'rows' => [
          ] }
        ]
      }
      expect($api).to receive(:post_query).and_return(data)

      col = Osm::FlexiRecord::Column.new(
        flexi_record: @flexi_record,
        id: 'f_1',
        name: 'name',
        editable: true
      )
      expect(col.delete($api)).to eq(false)
    end

    it 'Uneditable' do
      col = Osm::FlexiRecord::Column.new(
        flexi_record: @flexi_record,
        id: 'f_1',
        name: 'name',
        editable: false
      )
      expect($api).not_to receive(:post_query)
      expect{ col.delete($api) }.to raise_error(Osm::Forbidden)
    end

  end # desxribe delete











end
