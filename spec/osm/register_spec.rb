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

  it "Create Data" do
    rd = Osm::Register::Attendance.new(
      :member_id => '1',
      :first_name => 'A',
      :last_name => 'B',
      :section_id => '2',
      :grouping_id => '3',
      :total => 4,
      :attendance => {
        Date.new(2012, 1, 10) => 'Yes',
        Date.new(2012, 1, 24) => 'No',
      }
    )

    rd.member_id.should == 1
    rd.section_id.should == 2
    rd.grouping_id.should == 3
    rd.first_name.should == 'A'
    rd.last_name.should == 'B'
    rd.total.should == 4
    rd.attendance.should == {
      Date.new(2012, 01, 10) => 'Yes',
      Date.new(2012, 01, 24) => 'No'
    }
    rd.valid?.should be_true
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

      register = Osm::Register.get_attendance(@api, 1, 2)
      register.is_a?(Array).should be_true
      register.size.should == 1
      reg = register[0]
      reg.attendance.should == {
        Date.new(2000, 1, 1) => 'Yes',
        Date.new(2000, 1, 2) => 'No'
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

      HTTParty.should_receive(:post).with(url, {:body => post_data}) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'[]'}) }
      Osm::Register.update_attendance({
        :api => @api,
        :section => Osm::Section.new(:id=>1, :type=>:cubs),
        :term => 2,
        :evening => Date.new(2000, 1, 2),
        :attendance => 'Yes',
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

      register = Osm::Register.get_attendance(@api, 1, 2)
      register.is_a?(Array).should be_true
      register.size.should == 1
      reg = register[0]
      reg.first_name.should == 'First'
      reg.last_name.should == 'Last'
    end

    it "Handles no data" do
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
