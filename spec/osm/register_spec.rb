# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Register" do

  it "Create Field" do
    field = Osm::Register::Field.new(
      name: 'Human name',
      id: 'machine_name',
      tooltip: 'Tooltip'
    )

    expect(field.id).to eq('machine_name')
    expect(field.name).to eq('Human name')
    expect(field.tooltip).to eq('Tooltip')
    expect(field.valid?).to eq(true)
  end

  it "Sorts Field by id" do
    a1 = Osm::Register::Field.new(id: 'a')
    a2 = Osm::Register::Field.new(id: 'a')

    data = [a2, a1]
    expect(data.sort).to eq([a1, a2])
  end


  it "Create Attendance" do
    rd = Osm::Register::Attendance.new(
      member_id: '1',
      first_name: 'A',
      last_name: 'B',
      section_id: '2',
      grouping_id: '3',
      total: 4,
      attendance: {
        Date.new(2012, 1, 10) => :yes,
        Date.new(2012, 1, 24) => :unadvised_absent,
      }
    )

    expect(rd.member_id).to eq(1)
    expect(rd.section_id).to eq(2)
    expect(rd.grouping_id).to eq(3)
    expect(rd.first_name).to eq('A')
    expect(rd.last_name).to eq('B')
    expect(rd.total).to eq(4)
    expect(rd.attendance).to eq({
      Date.new(2012, 01, 10) => :yes,
      Date.new(2012, 01, 24) => :unadvised_absent
    })
    expect(rd.valid?).to eq(true)
  end

  it "Sorts Attendance by section_id, grouping_id, last_name then first_name" do
    d1 = Osm::Register::Attendance.new(section_id: 1, grouping_id: 1, last_name: 'a', first_name: 'a')
    d2 = Osm::Register::Attendance.new(section_id: 2, grouping_id: 1, last_name: 'a', first_name: 'a')
    d3 = Osm::Register::Attendance.new(section_id: 2, grouping_id: 2, last_name: 'a', first_name: 'a')
    d4 = Osm::Register::Attendance.new(section_id: 2, grouping_id: 2, last_name: 'b', first_name: 'a')
    d5 = Osm::Register::Attendance.new(section_id: 2, grouping_id: 2, last_name: 'b', first_name: 'b')

    data = [d4, d3, d5, d2, d1]
    expect(data.sort).to eq([d1, d2, d3, d4, d5])
  end

  it "Reports if a member was present on a date" do
    date = Date.new(2000, 1, 1)
    expect(Osm::Register::Attendance.new(attendance: {date => :yes}).present_on?(date)).to eq(true)
    expect(Osm::Register::Attendance.new(attendance: {date => :known_absent}).present_on?(date)).to eq(false)
    expect(Osm::Register::Attendance.new(attendance: {date => :unknown_absent}).present_on?(date)).to eq(false)
  end

  it "Reports if a member was absent on a date" do
    date = Date.new(2000, 1, 1)
    expect(Osm::Register::Attendance.new(attendance: {date => :yes}).absent_on?(date)).to eq(false)
    expect(Osm::Register::Attendance.new(attendance: {date => :known_absent}).absent_on?(date)).to eq(true)
    expect(Osm::Register::Attendance.new(attendance: {date => :unknown_absent}).absent_on?(date)).to eq(true)
  end


  describe "Using the API" do

    it "Fetch the register structure for a section" do
      data = [
        {"rows" => [{"name"=>"First name","field"=>"firstname","width"=>"100px"},{"name"=>"Last name","field"=>"lastname","width"=>"100px"},{"name"=>"Total","field"=>"total","width"=>"60px"}],"noscroll"=>true},
        {"rows" => []}
      ]
      expect($api).to receive(:post_query).with("users.php?action=registerStructure&sectionid=1&termid=2"){ data }

      register_structure = Osm::Register.get_structure(api: $api, section: 1, term: 2)
      expect(register_structure.is_a?(Array)).to eq(true)
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
      expect($api).to receive(:post_query).with("users.php?action=register&sectionid=1&termid=2") { data }
      allow(Osm::Register).to receive(:get_structure) { [
        Osm::Register::Field.new(id: '2000-01-01', name: 'Name', tooltip: 'Tooltip'),
        Osm::Register::Field.new(id: '2000-01-02', name: 'Name', tooltip: 'Tooltip'),
        Osm::Register::Field.new(id: '2000-01-03', name: 'Name', tooltip: 'Tooltip'),
      ] }

      register = Osm::Register.get_attendance(api: $api, section: 1, term: 2)
      expect(register.is_a?(Array)).to eq(true)
      expect(register.size).to eq(1)
      reg = register[0]
      expect(reg.attendance).to eq({
        Date.new(2000, 1, 1) => :yes,
        Date.new(2000, 1, 2) => :advised_absent,
        Date.new(2000, 1, 3) => :unadvised_absent,
      })
      expect(reg.first_name).to eq('First')
      expect(reg.last_name).to eq('Last')
      expect(reg.grouping_id).to eq(3)
      expect(reg.member_id).to eq(2)
      expect(reg.total).to eq(4)
      expect(reg.section_id).to eq(1)
      expect(reg.valid?).to eq(true)
    end

    it "Update register attendance" do
      post_data = {
        'scouts' => '["3"]',
        'selectedDate' => '2000-01-02',
        'present' => 'Yes',
        'section' => :cubs,
        'sectionid' => 1,
        'completedBadges' => '[{"a":"A"},{"b":"B"}]'
      }
      expect($api).to receive(:post_query).with("users.php?action=registerUpdate&sectionid=1&termid=2", post_data: post_data){ [] }

      expect(Osm::Register.update_attendance(
        api: $api,
        section: Osm::Section.new(id: 1, type: :cubs),
        term: 2,
        date: Date.new(2000, 1, 2),
        attendance: :yes,
        members: 3,
        completed_badge_requirements: [{'a'=>'A'}, {'b'=>'B'}]
      )).to eq(true)
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
      expect($api).to receive(:post_query).with("users.php?action=register&sectionid=1&termid=2"){ data }
      allow(Osm::Register).to receive(:get_structure) { [] }

      register = Osm::Register.get_attendance(api: $api, section: 1, term: 2)
      expect(register.is_a?(Array)).to eq(true)
      expect(register.size).to eq(1)
      reg = register[0]
      expect(reg.first_name).to eq('First')
      expect(reg.last_name).to eq('Last')
    end

    it "Handles no data getting structure" do
      expect($api).to receive(:post_query).with("users.php?action=registerStructure&sectionid=1&termid=2") { nil }
      register_structure = Osm::Register.get_structure(api: $api, section: 1, term: 2)
      expect(register_structure.is_a?(Array)).to eq(true)
      expect(register_structure.size).to eq(0)
    end

  end

end
