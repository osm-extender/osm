# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Flexi Record" do

  it "Create" do
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

  describe "FlexiRecord::Column" do

    it "Create" do
      field = Osm::FlexiRecord::Column.new(
        id: "f_1",
        name: "Field Name",
        editable: true,
        flexi_record: Osm::FlexiRecord.new(),
      )

      expect(field.id).to eq('f_1')
      expect(field.name).to eq('Field Name')
      expect(field.editable).to eq(true)
      expect(field.valid?).to eq(true)
    end

    it "Sorts by flexirecord then id (system first then user)" do
      frc1 = Osm::FlexiRecord::Column.new(flexi_record: Osm::FlexiRecord.new(section_id: 1), id: 'f_1')
      frc2 = Osm::FlexiRecord::Column.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), id: 'a')
      frc3 = Osm::FlexiRecord::Column.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), id: 'b')
      frc4 = Osm::FlexiRecord::Column.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), id: 'f_1')
      frc5 = Osm::FlexiRecord::Column.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), id: 'f_2')

      columns = [frc3, frc2, frc1, frc5, frc4]
      expect(columns.sort).to eq([frc1, frc2, frc3, frc4, frc5])
    end

  end


  describe "FlexiRecord::Data" do

    it "Create" do
      rd = Osm::FlexiRecord::Data.new(
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
          'f_2' => 'b',
        },
        flexi_record: Osm::FlexiRecord.new()
      )

      expect(rd.member_id).to eq(1)
      expect(rd.grouping_id).to eq(2)
      expect(rd.fields).to eq({
        'firstname' => 'First',
        'lastname' => 'Last',
        'dob' => Date.new(1899, 11, 30),
        'total' => 3,
        'completed' => nil,
        'age' => nil,
        'f_1' => 'a',
        'f_2' => 'b',
      })
      expect(rd.valid?).to eq(true)
    end

    it "Sorts by flexirecord, grouping_id then member_id" do
      frd1 = Osm::FlexiRecord::Data.new(flexi_record: Osm::FlexiRecord.new(section_id: 1), grouping_id: 1, member_id: 1)
      frd2 = Osm::FlexiRecord::Data.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), grouping_id: 1, member_id: 1)
      frd3 = Osm::FlexiRecord::Data.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), grouping_id: 2, member_id: 1)
      frd4 = Osm::FlexiRecord::Data.new(flexi_record: Osm::FlexiRecord.new(section_id: 2), grouping_id: 2, member_id: 2)

      datas = [frd3, frd2, frd1, frd4]
      expect(datas.sort).to eq([frd1, frd2, frd3, frd4])
    end

  end


  it "Sorts by section ID then name" do
    fr1 = Osm::FlexiRecord.new(section_id: 1, name: 'A')
    fr2 = Osm::FlexiRecord.new(section_id: 2, name: 'B')
    fr3 = Osm::FlexiRecord.new(section_id: 2, name: 'C')
    records = [fr2, fr1, fr3]

    expect(records.sort).to eq([fr1, fr2, fr3])
  end


  describe "Using the API" do

    before :each do
      @flexi_record = Osm::FlexiRecord.new(section_id: 1, id: 2, name: 'A Flexi Record')
    end

    it "Fetch Fields" do
      data = {
        "extraid" => "2",
        "sectionid" => "1",
        "name" => "A Flexi Record",
        "config" => "[{\"id\":\"f_1\",\"name\":\"Field 1\",\"width\":\"150\"},{\"id\":\"f_2\",\"name\":\"Field 2\",\"width\":\"150\"}]",
        "total" => "none",
        "extrafields" => "[]",
        "structure" => [
          {
            "rows" => [
              {"name" => "First name","field" => "firstname","width" => "150px"},
              {"name" => "Last name","field" => "lastname","width" => "150px"},
            ],
            "noscroll" => true
          },
          {"rows" => [
            {"name" => "Field 1","field" => "f_1","width" => "150px","editable" => true},
            {"name" => "Filed 2","field" => "f_2","width" => "150px","editable" => true},
          ]}
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

    it "Add field (success)" do
      post_data = {
        'columnName' => 'name',
      }

      data = {
        "extraid" => "2",
        "sectionid" => "1",
        "name" => "A Flexi Record",
        "config" => "[{\"id\":\"f_1\",\"name\":\"name\",\"width\":\"150\"}]",
        "total" => "none",
        "extrafields" => "[]",
        "structure" => [
          {
            "rows" => [
              {"name" => "First name","field" => "firstname","width" => "150px"},
              {"name" => "Last name","field" => "lastname","width" => "150px"},
            ],
            "noscroll" => true
          },
          {"rows" => [
            {"name" => "name","field" => "f_1","width" => "150px","editable" => true},
          ]}
        ]
      }
      expect($api).to receive(:post_query).with('extras.php?action=addColumn&sectionid=1&extraid=2', post_data: post_data).and_return(data)

      expect(@flexi_record.add_column(api: $api, name: 'name')).to eq(true)
    end

    it "Add field (failure)" do
      data = {
        "extraid" => "2",
        "sectionid" => "1",
        "name" => "A Flexi Record",
        "config" => "[]",
        "total" => "none",
        "extrafields" => "[]",
        "structure" => [
          {
            "rows" => [
              {"name" => "First name","field" => "firstname","width" => "150px"},
              {"name" => "Last name","field" => "lastname","width" => "150px"},
            ],
            "noscroll" => true
          },
          {"rows" => [
          ]}
        ]
      }
      expect($api).to receive(:post_query).and_return(data)

      expect(@flexi_record.add_column(api: $api, name: 'name')).to eq(false)
    end

    it "Update field (success)" do
      post_data = {
        'columnId' => 'f_1',
        'columnName' => 'name',
      }

      data = {
        "extraid" => "2",
        "sectionid" => "1",
        "name" => "A Flexi Record",
        "config" => "[{\"id\":\"f_1\",\"name\":\"name\",\"width\":\"150\"}]",
        "total" => "none",
        "extrafields" => "[]",
        "structure" => [
          {
            "rows" => [
              {"name" => "First name","field" => "firstname","width" => "150px"},
              {"name" => "Last name","field" => "lastname","width" => "150px"},
            ],
            "noscroll" => true
          },
          {"rows" => [
            {"name" => "name","field" => "f_1","width" => "150px","editable" => true},
          ]}
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

    it "Update field (failure)" do
      data = {
        "extraid" => "2",
        "sectionid" => "1",
        "name" => "A Flexi Record",
        "config" => "[]",
        "total" => "none",
        "extrafields" => "[]",
        "structure" => [
          {
            "rows" => [
              {"name" => "First name","field" => "firstname","width" => "150px"},
              {"name" => "Last name","field" => "lastname","width" => "150px"},
            ],
            "noscroll" => true
          },
          {"rows" => [
          ]}
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

    it "Update field (uneditable)" do
      col = Osm::FlexiRecord::Column.new(
        flexi_record: @flexi_record,
        id: 'f_1',
        name: 'name',
        editable: false
      )
      expect($api).not_to receive(:post_query)
      expect{ col.update($api) }.to raise_error(Osm::Forbidden)
    end

    it "Delete field (success)" do
      post_data = {
        'columnId' => 'f_1',
      }
      data = {
        "extraid" => "2",
        "sectionid" => "1",
        "name" => "A Flexi Record",
        "config" => "[]",
        "total" => "none",
        "extrafields" => "[]",
        "structure" => [
          {
            "rows" => [
              {"name" => "First name","field" => "firstname","width" => "150px"},
              {"name" => "Last name","field" => "lastname","width" => "150px"},
            ],
            "noscroll" => true
          },
          {"rows" => []}
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

    it "Delete field (failure)" do
      data = {
        "extraid" => "2",
        "sectionid" => "1",
        "name" => "A Flexi Record",
        "config" => "[{\"id\":\"f_1\",\"name\":\"name\",\"width\":\"150\"}]",
        "total" => "none",
        "extrafields" => "[]",
        "structure" => [
          {
            "rows" => [
              {"name" => "First name","field" => "firstname","width" => "150px"},
              {"name" => "Last name","field" => "lastname","width" => "150px"},
            ],
            "noscroll" => true
          },
          {"rows" => [
          ]}
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

    it "Delete field (uneditable)" do
      col = Osm::FlexiRecord::Column.new(
        flexi_record: @flexi_record,
        id: 'f_1',
        name: 'name',
        editable: false
      )
      expect($api).not_to receive(:post_query)
      expect{ col.delete($api) }.to raise_error(Osm::Forbidden)
    end

    it "Fetch Data" do
      data = {
        'identifier' => 'scoutid',
        'label' => "name",
        'items' => [{
          "scoutid" => "1",
          "firstname" => "First",
          "lastname" => "Last",
          "dob" => "",
          "patrolid" => "2",
          "total" => "",
          "completed" => "",
          "f_1" => "A",
          "f_2" => "B",
          "age" => "",
          "patrol" => "Green"
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
      expect(record.fields).to eq({
        'firstname' => 'First',
        'lastname' => 'Last',
        'dob' => nil,
        'total' => nil,
        'completed' => nil,
        'age' => nil,
        'f_1' => 'A',
        'f_2' => 'B',
      })
      expect(record.valid?).to eq(true)
    end


    it "Update data (success)" do
      post_data = {
        'termid' => 3,
        'scoutid' => 4,
        'column' => 'f_1',
        'value' => 'value',
        'sectionid' => 1,
        'extraid' => 2,
      }

      data = {
        'items' => [
          {'f_1' => 'value', 'scoutid' => '4'},
        ]
      }
      expect($api).to receive(:post_query).with('extras.php?action=updateScout', post_data: post_data).and_return(data)
      allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 3) }

      fr = Osm::FlexiRecord.new(section_id: 1, id: 2)
      allow(fr).to receive(:get_columns) { [Osm::FlexiRecord::Column.new(id: 'f_1', editable: true)] }
      fr_data = Osm::FlexiRecord::Data.new(
        flexi_record: fr,
        member_id: 4,
        grouping_id: 5,
        fields: {'f_1' => '', 'f_2' => 'value'}
      )
      fr_data.fields['f_1'] = 'value'
      expect(fr_data.update($api)).to eq(true)
    end

    it "Update data (failed)" do
      data = {
        'items' => [
          {'f_1' => 'old value', 'scoutid' => '4'},
        ]
      }

      expect($api).to receive(:post_query).and_return(data)
      allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 1) }

      fr = Osm::FlexiRecord.new(section_id: 1, id: 2)
      allow(fr).to receive(:get_columns) { [Osm::FlexiRecord::Column.new(id: 'f_1', editable: true)] }

      fr_data = Osm::FlexiRecord::Data.new(
        flexi_record: fr,
        member_id: 4,
        grouping_id: 5,
        fields: {'f_1' => 'old value'}
      )
      fr_data.fields['f_1'] = 'new value'
      expect(fr_data.update($api)).to eq(false)
    end

    it "Update data (uneditable field)" do
      allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 1) }
      fr = Osm::FlexiRecord.new(section_id: 1, id: 2)
      allow(fr).to receive(:get_columns) { [Osm::FlexiRecord::Column.new(id: 'f_1', editable: false)] }
      expect($api).not_to receive(:post_query)

      fr_data = Osm::FlexiRecord::Data.new(
        flexi_record: fr,
        member_id: 4,
        grouping_id: 5,
        fields: {'f_1' => 'value'}
      )
      expect(fr_data.update($api)).to eq(true)
    end


    it "Handles the total row" do
      data = {
        'identifier' => 'scoutid',
        'label' => "name",
        'items' => [{
          "scoutid" => "-1",
          "firstname" => "TOTAL",
          "lastname" => "",
          "dob" => "",
          "patrolid" => "-1",
          "total" => 100,
          "completed" => 0,
          "f_1" => 25,
          "f_2" => 75,
          "age" => "",
          "patrol" => ""
        },{
          "scoutid" => "1",
          "firstname" => "First",
          "lastname" => "Last",
          "dob" => "",
          "patrolid" => "2",
          "total" => "",
          "completed" => "",
          "f_1" => "A",
          "f_2" => "B",
          "age" => "",
          "patrol" => "Green"
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

  describe "API Strangeness" do

    it "Calculated columns containing numbers not strings" do
      data = {
        'identifier' => 'scoutid',
        'label' => "name",
        'items' => [{
          "scoutid" => "1",
          "firstname" => "First",
          "lastname" => "Last",
          "dob" => "",
          "patrolid" => "2",
          "total" => 3,
          "completed" => 4,
          "f_1" => "A",
          "f_2" => "B",
          "age" => "",
          "patrol" => "Green"
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

