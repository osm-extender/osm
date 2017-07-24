describe OSM::FlexiRecord::Data do

  it 'Create' do
    rd = OSM::FlexiRecord::Data.new(
      member_id: 1,
      grouping_id: 2,
      fields: {
        'firstname' => 'First',
        'lastname' => 'Last',
        'dob' => Date.new(1899, 11, 30),
        'total' => 3,
        'completed' => nil,
        'age' => nil,
        'f_1' => 'a',
        'f_2' => 'b'
      },
      flexi_record: OSM::FlexiRecord.new()
    )

    expect(rd.member_id).to eq(1)
    expect(rd.grouping_id).to eq(2)
    expect(rd.fields).to eq(
      'firstname' => 'First',
      'lastname' => 'Last',
      'dob' => Date.new(1899, 11, 30),
      'total' => 3,
      'completed' => nil,
      'age' => nil,
      'f_1' => 'a',
      'f_2' => 'b'
    )
    expect(rd.valid?).to eq(true)
  end

  it 'Sorts by flexirecord, grouping_id then member_id' do
    frd1 = OSM::FlexiRecord::Data.new(flexi_record: OSM::FlexiRecord.new(section_id: 1), grouping_id: 1, member_id: 1)
    frd2 = OSM::FlexiRecord::Data.new(flexi_record: OSM::FlexiRecord.new(section_id: 2), grouping_id: 1, member_id: 1)
    frd3 = OSM::FlexiRecord::Data.new(flexi_record: OSM::FlexiRecord.new(section_id: 2), grouping_id: 2, member_id: 1)
    frd4 = OSM::FlexiRecord::Data.new(flexi_record: OSM::FlexiRecord.new(section_id: 2), grouping_id: 2, member_id: 2)

    datas = [frd3, frd2, frd1, frd4]
    expect(datas.sort).to eq([frd1, frd2, frd3, frd4])
  end


  describe 'Update' do

    it 'Success' do
      post_data = {
        'termid' => 3,
        'scoutid' => 4,
        'column' => 'f_1',
        'value' => 'value',
        'sectionid' => 1,
        'extraid' => 2
      }

      data = {
        'items' => [
          { 'f_1' => 'value', 'scoutid' => '4' }
        ]
      }
      expect($api).to receive(:post_query).with('extras.php?action=updateScout', post_data: post_data).and_return(data)
      allow(OSM::Term).to receive(:get_current_term_for_section) { OSM::Term.new(id: 3) }

      fr = OSM::FlexiRecord.new(section_id: 1, id: 2)
      allow(fr).to receive(:get_columns) { [OSM::FlexiRecord::Column.new(id: 'f_1', editable: true)] }
      fr_data = OSM::FlexiRecord::Data.new(
        flexi_record: fr,
        member_id: 4,
        grouping_id: 5,
        fields: { 'f_1' => '', 'f_2' => 'value' }
      )
      fr_data.fields['f_1'] = 'value'
      expect(fr_data.update($api)).to eq(true)
    end

    it 'Failed' do
      data = {
        'items' => [
          { 'f_1' => 'old value', 'scoutid' => '4' }
        ]
      }

      expect($api).to receive(:post_query).and_return(data)
      allow(OSM::Term).to receive(:get_current_term_for_section) { OSM::Term.new(id: 1) }

      fr = OSM::FlexiRecord.new(section_id: 1, id: 2)
      allow(fr).to receive(:get_columns) { [OSM::FlexiRecord::Column.new(id: 'f_1', editable: true)] }

      fr_data = OSM::FlexiRecord::Data.new(
        flexi_record: fr,
        member_id: 4,
        grouping_id: 5,
        fields: { 'f_1' => 'old value' }
      )
      fr_data.fields['f_1'] = 'new value'
      expect(fr_data.update($api)).to eq(false)
    end

    it 'Uneditable field' do
      allow(OSM::Term).to receive(:get_current_term_for_section) { OSM::Term.new(id: 1) }
      fr = OSM::FlexiRecord.new(section_id: 1, id: 2)
      allow(fr).to receive(:get_columns) { [OSM::FlexiRecord::Column.new(id: 'f_1', editable: false)] }
      expect($api).not_to receive(:post_query)

      fr_data = OSM::FlexiRecord::Data.new(
        flexi_record: fr,
        member_id: 4,
        grouping_id: 5,
        fields: { 'f_1' => 'value' }
      )
      expect(fr_data.update($api)).to eq(true)
    end

  end # describe update

end
