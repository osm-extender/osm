# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Register" do

  it "Create Field" do
    field = Osm::Register::Field.new(
      :name => 'Human name',
      :id => 'machine_name',
      :tooltip => 'Tooltip'
    )

    field.id.should == 'machine_name'
    field.name.should == 'Human name'
    field.tooltip.should == 'Tooltip'
    field.valid?.should be_true
  end

  it "Sorts Field by id" do
    a1 = Osm::Register::Field.new(:id => 'a')
    a2 = Osm::Register::Field.new(:id => 'a')

    data = [a2, a1]
    data.sort.should == [a1, a2]
  end


  it "Create Attendance" do
    rd = Osm::Register::Attendance.new(
      :member_id => '1',
      :first_name => 'A',
      :last_name => 'B',
      :section_id => '2',
      :grouping_id => '3',
      :total => 4,
      :attendance => {
        Date.new(2012, 1, 10) => :yes,
        Date.new(2012, 1, 24) => :unadvised_absent,
      }
    )

    rd.member_id.should == 1
    rd.section_id.should == 2
    rd.grouping_id.should == 3
    rd.first_name.should == 'A'
    rd.last_name.should == 'B'
    rd.total.should == 4
    rd.attendance.should == {
      Date.new(2012, 01, 10) => :yes,
      Date.new(2012, 01, 24) => :unadvised_absent
    }
    rd.valid?.should be_true
  end

  it "Sorts Attendance by section_id, grouping_id, last_name then first_name" do
    d1 = Osm::Register::Attendance.new(:section_id => 1, :grouping_id => 1, :last_name => 'a', :first_name => 'a')
    d2 = Osm::Register::Attendance.new(:section_id => 2, :grouping_id => 1, :last_name => 'a', :first_name => 'a')
    d3 = Osm::Register::Attendance.new(:section_id => 2, :grouping_id => 2, :last_name => 'a', :first_name => 'a')
    d4 = Osm::Register::Attendance.new(:section_id => 2, :grouping_id => 2, :last_name => 'b', :first_name => 'a')
    d5 = Osm::Register::Attendance.new(:section_id => 2, :grouping_id => 2, :last_name => 'b', :first_name => 'b')

    data = [d4, d3, d5, d2, d1]
    data.sort.should == [d1, d2, d3, d4, d5]
  end


  describe "Using the API" do

    it "Fetch the register structure for a section" do
      data = [
        {"rows" => [{"name"=>"First name","field"=>"firstname","width"=>"100px"},{"name"=>"Last name","field"=>"lastname","width"=>"100px"},{"name"=>"Total","field"=>"total","width"=>"60px"}],"noscroll"=>true},
        {"rows" => []}
      ]
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=registerStructure&sectionid=1&termid=2", :body => data.to_json)

      register_structure = Osm::Register.get_structure(@api, 1, 2)
      register_structure.is_a?(Array).should be_true
    end

    it "Fetch the register data for a section" do
      data = {
        'identifier' => 'scoutid',
        'label' => "name",
        'items' => [
          {
            "total" => 4,
            "2000-01-01" => "Yes",
            "2000-01-02" => "No",
            "scoutid" => "2",
            "firstname" => "First",
            "lastname" => "Last",
            "patrolid" => "3"
          }
        ]
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=register&sectionid=1&termid=2", :body => data.to_json)
      Osm::Register.stub(:get_structure) { [
        Osm::Register::Field.new(:id => '2000-01-01', :name => 'Name', :tooltip => 'Tooltip'),
        Osm::Register::Field.new(:id => '2000-01-02', :name => 'Name', :tooltip => 'Tooltip'),
        Osm::Register::Field.new(:id => '2000-01-03', :name => 'Name', :tooltip => 'Tooltip'),
      ] }

      register = Osm::Register.get_attendance(@api, 1, 2)
      register.is_a?(Array).should be_true
      register.size.should == 1
      reg = register[0]
      reg.attendance.should == {
        Date.new(2000, 1, 1) => :yes,
        Date.new(2000, 1, 2) => :advised_absent,
        Date.new(2000, 1, 3) => :unadvised_absent,
      }
      reg.first_name.should == 'First'
      reg.last_name.should == 'Last'
      reg.grouping_id.should == 3
      reg.member_id.should == 2
      reg.total.should == 4
      reg.section_id.should == 1
      reg.valid?.should be_true
    end

    it "Update register attendance" do
      url = 'https://www.onlinescoutmanager.co.uk/users.php?action=registerUpdate&sectionid=1&termid=2'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'scouts' => '["3"]',
        'selectedDate' => '2000-01-02',
        'present' => 'Yes',
        'section' => :cubs,
        'sectionid' => 1,
        'completedBadges' => '[{"a":"A"},{"b":"B"}]'
      }

      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'[]'}) }
      Osm::Register.update_attendance({
        :api => @api,
        :section => Osm::Section.new(:id=>1, :type=>:cubs),
        :term => 2,
        :evening => Date.new(2000, 1, 2),
        :attendance => :yes,
        :members => 3,
        :completed_badge_requirements => [{'a'=>'A'}, {'b'=>'B'}]
      }).should be_true
    end

    it "Handles the total row" do
      data = {
        'identifier' => 'scoutid',
        'label' => "name",
        'items' => [
          {
            "total" => 1,
            "scoutid" => "2",
            "firstname" => "First",
            "lastname" => "Last",
            "patrolid" => "3"
          },{
            "total" => 119,
            "2000-01-01" => 8,
            "scoutid" => -1,
            "firstname" => "TOTAL",
            "lastname" => "",
            "patrolid" => 0
          }
        ]
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=register&sectionid=1&termid=2", :body => data.to_json)
      Osm::Register.stub(:get_structure) { [] }

      register = Osm::Register.get_attendance(@api, 1, 2)
      register.is_a?(Array).should be_true
      register.size.should == 1
      reg = register[0]
      reg.first_name.should == 'First'
      reg.last_name.should == 'Last'
    end

    it "Handles no data getting structure" do
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=registerStructure&sectionid=1&termid=2", :body => '')
      register_structure = Osm::Register.get_structure(@api, 1, 2)
      register_structure.is_a?(Array).should be_true
      register_structure.size.should == 0


      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=register&sectionid=1&termid=2", :body => '')
      register = Osm::Register.get_attendance(@api, 1, 2)
      register.is_a?(Array).should be_true
      register.size.should == 0
    end

  end

end
