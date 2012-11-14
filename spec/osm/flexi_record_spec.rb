# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Flexi Record" do

  it "Create FlexiRecord::Field" do
    field = Osm::FlexiRecord::Field.new(
      :id => "f_1",
      :name => "Field Name",
      :editable => true
    )

    field.id.should == 'f_1'
    field.name.should == 'Field Name'
    field.editable.should be_true
    field.valid?.should be_true
  end

  it "Create FlexiRecord::Data" do
    rd = Osm::FlexiRecord::Data.new(
      :member_id => 1,
      :grouping_id => 2,
      :fields => {
        'firstname' => 'First',
        'lastname' => 'Last',
        'dob' => Date.new(1899, 11, 30),
        'total' => 3,
        'completed' => nil,
        'age' => nil,
        'f_1' => 'a',
        'f_2' => 'b',
      }
    )

    rd.member_id.should == 1
    rd.grouping_id.should == 2
    rd.fields.should == {
      'firstname' => 'First',
      'lastname' => 'Last',
      'dob' => Date.new(1899, 11, 30),
      'total' => 3,
      'completed' => nil,
      'age' => nil,
      'f_1' => 'a',
      'f_2' => 'b',
    }
    rd.valid?.should be_true
  end


  describe "Using the API" do

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
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/extras.php?action=getExtra&sectionid=1&extraid=2", :body => data.to_json)

      fields = Osm::FlexiRecord.get_fields(@api, 1, 2)
      fields.is_a?(Array).should be_true
      fields[0].valid?.should be_true
      fields[0].id.should == 'firstname'
      fields[1].id.should == 'lastname'
      fields[2].id.should == 'f_1'
      fields[3].id.should == 'f_2'
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
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/extras.php?action=getExtraRecords&sectionid=1&extraid=2&termid=3&section=cubs", :body => data.to_json)

      records = Osm::FlexiRecord.get_data(@api, Osm::Section.new(:id => 1, :type => :cubs), 2, 3)
      records.is_a?(Array).should be_true
      records.size.should == 1
      record = records[0]
      record.member_id.should == 1
      record.grouping_id.should == 2
      record.fields.should == {
        'firstname' => 'First',
        'lastname' => 'Last',
        'dob' => nil,
        'total' => nil,
        'completed' => nil,
        'age' => nil,
        'f_1' => 'A',
        'f_2' => 'B',
      }
      record.valid?.should be_true
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
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/extras.php?action=getExtraRecords&sectionid=1&extraid=2&termid=3&section=cubs", :body => data.to_json)

      records = Osm::FlexiRecord.get_data(@api, Osm::Section.new(:id => 1, :type => :cubs), 2, 3)
      records.is_a?(Array).should be_true
      records.size.should == 1
      record = records[0]
      record.member_id.should == 1
      record.grouping_id.should == 2
      record.fields['firstname'].should == 'First'
      record.fields['lastname'].should == 'Last'
    end


  end

end
