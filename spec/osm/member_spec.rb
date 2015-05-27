# encoding: utf-8
require 'spec_helper'

describe "Member" do

  it "Create" do
    attributes = {
      :id => 1,
      :section_id => 2,
      :first_name => 'First',
      :last_name => 'Last',
      :date_of_birth => '2000-01-02',
      :grouping_id => '3',
      :grouping_leader => 0,
      :grouping_label => 'Grouping',
      :grouping_leader_label => '6er',
      :age => '06 / 07',
      :gender => :other,
      :joined_movement => '2006-01-02',
      :started_section => '2006-01-07',
      :finished_section => '2007-12-31',
      :custom => {'12_3' => '123'},
      :custom_labels => {'12_3' => 'Label for 123'},
      :contact => Osm::Member::MemberContact.new(postcode: 'A'),
      :primary_contact => Osm::Member::PrimaryContact.new(postcode: 'B'),
      :secondary_contact => Osm::Member::PrimaryContact.new(postcode: 'C'),
      :emergency_contact => Osm::Member::EmergencyContact.new(postcode: 'D'),
      :doctor => Osm::Member::DoctorContact.new(postcode: 'E'),
    }
    member = Osm::Member.new(attributes)

    member.id.should == 1
    member.section_id.should == 2
    member.first_name.should == 'First'
    member.last_name.should == 'Last'
    member.date_of_birth.should == Date.new(2000, 1, 2)
    member.grouping_id.should == 3
    member.grouping_leader.should == 0
    member.grouping_label.should == 'Grouping'
    member.grouping_leader_label.should == '6er'
    member.age.should == '06 / 07'
    member.gender.should == :other
    member.joined_movement.should == Date.new(2006, 1, 2)
    member.started_section.should == Date.new(2006, 1, 7)
    member.finished_section.should == Date.new(2007, 12, 31)
    member.custom.should == {'12_3' => '123'}
    member.custom_labels.should == {'12_3' => 'Label for 123'}
    member.contact.postcode.should == 'A'
    member.primary_contact.postcode.should == 'B'
    member.secondary_contact.postcode.should == 'C'
    member.emergency_contact.postcode.should == 'D'
    member.doctor.postcode.should == 'E'
    member.valid?.should == true
  end


  it "Provides member's full name" do
    data = {
      :first_name => 'First',
      :last_name => 'Last',
    }
    member = Osm::Member.new(data)

    member.name.should == 'First Last'
    member.name('_').should == 'First_Last'
  end

  it "Tells if member is a leader" do
    Osm::Member.new(grouping_id: -2).leader?.should == true  # In the leader grouping
    Osm::Member.new(grouping_id: 2).leader?.should == false  # In a youth grouping
    Osm::Member.new(grouping_id: 0).leader?.should == false  # Not in a grouping
  end

  it "Tells if member is a youth member" do
    Osm::Member.new(grouping_id: -2).youth?.should == false  # In the leader grouping
    Osm::Member.new(grouping_id: 2).youth?.should == true  # In a youth grouping
    Osm::Member.new(grouping_id: 0).youth?.should == false  # Not in a grouping
  end

  it "Provides each part of age" do
    data = {
      :age => '06/07',
    }
    member = Osm::Member.new(data)

    member.age_years.should == 6
    member.age_months.should == 7
  end

  it "Tells if the member is male" do
    Osm::Member.new(gender: :male).male?.should == true
    Osm::Member.new(gender: :female).male?.should == false
    Osm::Member.new(gender: :other).male?.should == false
    Osm::Member.new(gender: :unspecified).male?.should == false
    Osm::Member.new(gender: nil).male?.should == false
  end

  it "Tells if the member is female" do
    Osm::Member.new(gender: :female).female?.should == true
    Osm::Member.new(gender: :male).female?.should == false
    Osm::Member.new(gender: :other).female?.should == false
    Osm::Member.new(gender: :unspecified).female?.should == false
    Osm::Member.new(gender: nil).female?.should == false
  end


  describe "Tells if the member is currently in the section" do
    it "Today" do
      Osm::Member.new(started_section: Date.yesterday).current?.should == true
      Osm::Member.new(started_section: Date.today).current?.should == true
      Osm::Member.new(started_section: Date.tomorrow).current?.should == false
      Osm::Member.new(started_section: Date.yesterday, finished_section: Date.yesterday).current?.should == false
      Osm::Member.new(started_section: Date.yesterday, finished_section: Date.today).current?.should == true
      Osm::Member.new(started_section: Date.yesterday, finished_section: Date.tomorrow).current?.should == true
    end

    it "Another date" do
      yesterday = Date.new(2014, 10, 15)
      today = Date.new(2014, 10, 16)
      tomorrow = Date.new(2014, 10, 17)
      Osm::Member.new(started_section: yesterday).current?(today).should == true
      Osm::Member.new(started_section: today).current?(today).should == true
      Osm::Member.new(started_section: tomorrow).current?(today).should == false
      Osm::Member.new(started_section: yesterday, finished_section: yesterday).current?(today).should == false
      Osm::Member.new(started_section: yesterday, finished_section: today).current?(today).should == true
      Osm::Member.new(started_section: yesterday, finished_section: tomorrow).current?(today).should == true
    end
  end


  it "Sorts by section_id, grouping_id, grouping_leader (descending), last_name then first_name" do
    m1 = Osm::Member.new(:section_id => 1, :grouping_id => 1, :grouping_leader => 1, :last_name => 'a', :first_name => 'a')
    m2 = Osm::Member.new(:section_id => 2, :grouping_id => 1, :grouping_leader => 1, :last_name => 'a', :first_name => 'a')
    m3 = Osm::Member.new(:section_id => 2, :grouping_id => 2, :grouping_leader => 1, :last_name => 'a', :first_name => 'a')
    m4 = Osm::Member.new(:section_id => 2, :grouping_id => 2, :grouping_leader => 0, :last_name => 'a', :first_name => 'a')
    m5 = Osm::Member.new(:section_id => 2, :grouping_id => 2, :grouping_leader => 0, :last_name => 'a', :first_name => 'a')
    m6 = Osm::Member.new(:section_id => 2, :grouping_id => 2, :grouping_leader => 0, :last_name => 'b', :first_name => 'a')
    m7 = Osm::Member.new(:section_id => 2, :grouping_id => 2, :grouping_leader => 0, :last_name => 'b', :first_name => 'b')

    data = [m4, m2, m3, m1, m7, m6, m5]
    data.sort.should == [m1, m2, m3, m4, m5, m6, m7]
  end


  describe "Using the API" do

    it "Get from OSM" do
      body = {
        'status' => true,
        'error' => nil,
        'data' => {
          '123' => {
            'active' => true,
            'age' => '12 / 00',
            'date_of_birth' => '2000-03-08',
            'end_date' => '2010-06-03',
            'first_name' => 'John',
            'joined' => '2008-07-12',
            'last_name' => 'Smith',
            'member_id' => 123,
            'patrol' => 'Leaders',
            'patrol_id' => -2,
            'patrol_role_level' => 1,
            'patrol_role_level_label' => 'Assistant leader',
            'section_id' => 1,
            'started' => '2006-07-17',
            'custom_data' => {
              '1' => {'2' => 'Primary', '3' => 'Contact', '7' => 'Address 1', '8' => 'Address 2', '9' => 'Address 3', '10' => 'Address 4', '11' => 'Postcode', '12' => 'primary@example.com', '13' => 'yes', '14' => '', '15' => '', '18' => '01234 567890', '19' => 'yes', '20' => '0987 654321', '21' => '', '8441' => 'Data for 8441'},
              '2' => {'2' => 'Secondary', '3' => 'Contact', '7' => 'Address 1', '8' => 'Address 2', '9' => 'Address 3', '10' => 'Address 4', '11' => 'Postcode', '12' => 'secondary@example.com', '13' => 'yes', '14' => '', '15' => '', '18' => '01234 567890', '19' => 'yes', '20' => '0987 654321', '21' => '', '8442' => 'Data for 8442'},
              '3' => {'2' => 'Emergency', '3' => 'Contact', '7' => 'Address 1', '8' => 'Address 2', '9' => 'Address 3', '10' => 'Address 4', '11' => 'Postcode', '12' => 'emergency@example.com', '14' => '', '18' => '01234 567890', '20' => '0987 654321', '21' => '', '8443' => 'Data for 8443'},
              '4' => {'2' => 'Doctor', '3' => 'Contact', '7' => 'Address 1', '8' => 'Address 2', '9' => 'Address 3', '10' => 'Address 4', '11' => 'Postcode', '18' => '01234 567890', '20' => '0987 654321', '21' => '', '54' => 'Surgery', '8444' => 'Data for 8444'},
              '5' => {'4848' => 'Data for 4848'},
              '6' => {'7' => 'Address 1', '8' => 'Address 2', '9' => 'Address 3', '10' => 'Address 4', '11' => 'Postcode', '12' => 'member@example.com', '13' => 'yes', '14' => '', '15' => '', '18' => '01234 567890', '19' => 'yes', '20' => '0987 654321', '21' => '', '8446' => 'Data for 8446'},
              '7' => {'34' => 'Unspecified'},
            },
          }
        },
        'meta' => {
          'leader_count' => 20,
          'member_count' => 30,
          'status' => true,
          'structure' => [
            {'group_id' => 1, 'description' => '', 'identifier' => 'contact_primary_1', 'name' => 'Primary Contact 1', 'columns' => [
              {'column_id' => 2, 'group_column_id' => '1_2', 'label' => 'First Name', 'varname' => 'firstname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 3, 'group_column_id' => '1_3', 'label' => 'Last Name', 'varname' => 'lastname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 7, 'group_column_id' => '1_7', 'label' => 'Address 1', 'varname' => 'address1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 8, 'group_column_id' => '1_8', 'label' => 'Address 2', 'varname' => 'address2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 9, 'group_column_id' => '1_9', 'label' => 'Address 3', 'varname' => 'address3', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 10, 'group_column_id' => '1_10', 'label' => 'Address 4', 'varname' => 'address4', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 11, 'group_column_id' => '1_11', 'label' => 'Postcode', 'varname' => 'postcode', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 12, 'group_column_id' => '1_12', 'label' => 'Email 1', 'varname' => 'email1', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120},
              {'column_id' => 14, 'group_column_id' => '1_14', 'label' => 'Email 2', 'varname' => 'email2', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120},
              {'column_id' => 18, 'group_column_id' => '1_18', 'label' => 'Phone 1', 'varname' => 'phone1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 20, 'group_column_id' => '1_20', 'label' => 'Phone 2', 'varname' => 'phone2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 8441, 'group_column_id' => '1_8441', 'label' => 'Label for 8441', 'varname' => 'label_for_8441', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
            {'group_id' => 2, 'description' => '', 'identifier' => 'contact_primary_2', 'name' => 'Primary Contact 2', 'columns' => [
              {'column_id' => 2, 'group_column_id' => '2_2', 'label' => 'First Name', 'varname' => 'firstname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 3, 'group_column_id' => '2_3', 'label' => 'Last Name', 'varname' => 'lastname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 7, 'group_column_id' => '2_7', 'label' => 'Address 1', 'varname' => 'address1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 8, 'group_column_id' => '2_8', 'label' => 'Address 2', 'varname' => 'address2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 9, 'group_column_id' => '2_9', 'label' => 'Address 3', 'varname' => 'address3', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 10, 'group_column_id' => '2_10', 'label' => 'Address 4', 'varname' => 'address4', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 11, 'group_column_id' => '2_11', 'label' => 'Postcode', 'varname' => 'postcode', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 12, 'group_column_id' => '2_12', 'label' => 'Email 1', 'varname' => 'email1', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120},
              {'column_id' => 14, 'group_column_id' => '2_14', 'label' => 'Email 2', 'varname' => 'email2', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120},
              {'column_id' => 18, 'group_column_id' => '2_18', 'label' => 'Phone 1', 'varname' => 'phone1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 20, 'group_column_id' => '2_20', 'label' => 'Phone 2', 'varname' => 'phone2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 8442, 'group_column_id' => '2_8442', 'label' => 'Label for 8442', 'varname' => 'label_for_8442', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
            {'group_id' => 3, 'description' => '', 'identifier' => 'emergency', 'name' => 'Emergency Contact', 'columns' => [
              {'column_id' => 2, 'group_column_id' => '3_2', 'label' => 'First Name', 'varname' => 'firstname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 3, 'group_column_id' => '3_3', 'label' => 'Last Name', 'varname' => 'lastname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 7, 'group_column_id' => '3_7', 'label' => 'Address 1', 'varname' => 'address1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 8, 'group_column_id' => '3_8', 'label' => 'Address 2', 'varname' => 'address2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 9, 'group_column_id' => '3_9', 'label' => 'Address 3', 'varname' => 'address3', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 10, 'group_column_id' => '3_10', 'label' => 'Address 4', 'varname' => 'address4', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 11, 'group_column_id' => '3_11', 'label' => 'Postcode', 'varname' => 'postcode', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 12, 'group_column_id' => '3_12', 'label' => 'Email 1', 'varname' => 'email1', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120},
              {'column_id' => 14, 'group_column_id' => '3_14', 'label' => 'Email 2', 'varname' => 'email2', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120},
              {'column_id' => 18, 'group_column_id' => '3_18', 'label' => 'Phone 1', 'varname' => 'phone1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 20, 'group_column_id' => '3_20', 'label' => 'Phone 2', 'varname' => 'phone2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 8443, 'group_column_id' => '3_8443', 'label' => 'Label for 8443', 'varname' => 'label_for_8443', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
            {'group_id' => 4, 'description' => '', 'identifier' => 'doctor', 'name' => "Doctor's Surgery", 'columns' => [
              {'column_id' => 2, 'group_column_id' => '4_2', 'label' => 'First Name', 'varname' => 'firstname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 3, 'group_column_id' => '4_3', 'label' => 'Last Name', 'varname' => 'lastname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 54, 'group_column_id' => '4_54', 'label' => 'Surgery', 'varname' => 'surgery', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 7, 'group_column_id' => '4_7', 'label' => 'Address 1', 'varname' => 'address1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 8, 'group_column_id' => '4_8', 'label' => 'Address 2', 'varname' => 'address2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 9, 'group_column_id' => '4_9', 'label' => 'Address 3', 'varname' => 'address3', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 10, 'group_column_id' => '4_10', 'label' => 'Address 4', 'varname' => 'address4', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 11, 'group_column_id' => '4_11', 'label' => 'Postcode', 'varname' => 'postcode', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 18, 'group_column_id' => '4_18', 'label' => 'Phone 1', 'varname' => 'phone1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 20, 'group_column_id' => '4_20', 'label' => 'Phone 2', 'varname' => 'phone2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 8444, 'group_column_id' => '4_8444', 'label' => 'Label for 8444', 'varname' => 'label_for_8444', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
            {'group_id' => 6, 'description' => '', 'identifier' => 'contact_member', 'name' => 'Member', 'columns' => [
              {'column_id' => 2, 'group_column_id' => '6_2', 'label' => 'First Name', 'varname' => 'firstname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 3, 'group_column_id' => '6_3', 'label' => 'Last Name', 'varname' => 'lastname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 7, 'group_column_id' => '6_7', 'label' => 'Address 1', 'varname' => 'address1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 8, 'group_column_id' => '6_8', 'label' => 'Address 2', 'varname' => 'address2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 9, 'group_column_id' => '6_9', 'label' => 'Address 3', 'varname' => 'address3', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 10, 'group_column_id' => '6_10', 'label' => 'Address 4', 'varname' => 'address4', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 11, 'group_column_id' => '6_11', 'label' => 'Postcode', 'varname' => 'postcode', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 12, 'group_column_id' => '6_12', 'label' => 'Email 1', 'varname' => 'email1', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120},
              {'column_id' => 14, 'group_column_id' => '6_14', 'label' => 'Email 2', 'varname' => 'email2', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120},
              {'column_id' => 18, 'group_column_id' => '6_18', 'label' => 'Phone 1', 'varname' => 'phone1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 20, 'group_column_id' => '6_20', 'label' => 'Phone 2', 'varname' => 'phone2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
              {'column_id' => 8446, 'group_column_id' => '6_8446', 'label' => 'Label for 8446', 'varname' => 'label_for_8446', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
            {'group_id' => 5, 'description' => 'This allows you to add  extra information for your members.', 'identifier' => 'customisable_data', 'name' => 'Customisable Data', 'columns' => [
              {'column_id' => 4848, 'group_column_id' => '5_4848', 'label' => 'Label for 4848', 'varname' => 'label_for_4848', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
            {'group_id' => 7, 'description' => '', 'identifier' => 'floating', 'name' => 'Floating', 'columns' => [
              {'column_id' => 34, 'group_column_id' => '7_34', 'label' => 'Gender', 'varname' => 'gender', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
          ],
        },
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/members/contact/grid/?action=getMembers", :body => body.to_json, :content_type => 'application/json')

      members = Osm::Member.get_for_section(@api, 1, 2)
      members.size.should == 1
      member = members[0]
      member.id.should == 123
      member.section_id.should == 1
      member.first_name.should == 'John'
      member.last_name.should == 'Smith'
      member.date_of_birth.should == Date.new(2000, 3, 8)
      member.grouping_id.should == -2
      member.grouping_leader.should == 1
      member.grouping_label.should == 'Leaders'
      member.grouping_leader_label.should == 'Assistant leader'
      member.age.should == '12 / 00'
      member.gender.should == :unspecified
      member.joined_movement.should == Date.new(2006, 7, 17)
      member.started_section.should == Date.new(2008, 7, 12)
      member.finished_section.should == Date.new(2010, 6, 3)
      member.custom.should == {"label_for_4848" => "Data for 4848"}
      member.custom_labels.should == {"label_for_4848" => 'Label for 4848'}
      member.contact.first_name.should == 'John'
      member.contact.last_name.should == 'Smith'
      member.contact.address_1.should == 'Address 1'
      member.contact.address_2.should == 'Address 2'
      member.contact.address_3.should == 'Address 3'
      member.contact.address_4.should == 'Address 4'
      member.contact.postcode.should == 'Postcode'
      member.contact.phone_1.should == '01234 567890'
      member.contact.receive_phone_1.should == true
      member.contact.phone_2.should == '0987 654321'
      member.contact.receive_phone_2.should == false
      member.contact.email_1.should == 'member@example.com'
      member.contact.receive_email_1.should == true
      member.contact.email_2.should == ''
      member.contact.receive_email_2.should == false
      member.contact.custom.should == {"label_for_8446"=>"Data for 8446"}
      member.contact.custom_labels.should == {"label_for_8446"=>"Label for 8446"}
      member.primary_contact.first_name.should == 'Primary'
      member.primary_contact.last_name.should == 'Contact'
      member.primary_contact.address_1.should == 'Address 1'
      member.primary_contact.address_2.should == 'Address 2'
      member.primary_contact.address_3.should == 'Address 3'
      member.primary_contact.address_4.should == 'Address 4'
      member.primary_contact.postcode.should == 'Postcode'
      member.primary_contact.phone_1.should == '01234 567890'
      member.primary_contact.receive_phone_1.should == true
      member.primary_contact.phone_2.should == '0987 654321'
      member.primary_contact.receive_phone_2.should == false
      member.primary_contact.email_1.should == 'primary@example.com'
      member.primary_contact.receive_email_1.should == true
      member.primary_contact.email_2.should == ''
      member.primary_contact.receive_email_2.should == false
      member.primary_contact.custom.should == {"label_for_8441"=>"Data for 8441"}
      member.primary_contact.custom_labels.should == {"label_for_8441"=>"Label for 8441"}
      member.secondary_contact.first_name.should == 'Secondary'
      member.secondary_contact.last_name.should == 'Contact'
      member.secondary_contact.address_1.should == 'Address 1'
      member.secondary_contact.address_2.should == 'Address 2'
      member.secondary_contact.address_3.should == 'Address 3'
      member.secondary_contact.address_4.should == 'Address 4'
      member.secondary_contact.postcode.should == 'Postcode'
      member.secondary_contact.phone_1.should == '01234 567890'
      member.secondary_contact.receive_phone_1.should == true
      member.secondary_contact.phone_2.should == '0987 654321'
      member.secondary_contact.receive_phone_2.should == false
      member.secondary_contact.email_1.should == 'secondary@example.com'
      member.secondary_contact.receive_email_1.should == true
      member.secondary_contact.email_2.should == ''
      member.secondary_contact.receive_email_2.should == false
      member.secondary_contact.custom.should == {"label_for_8442"=>"Data for 8442"}
      member.secondary_contact.custom_labels.should == {"label_for_8442"=>"Label for 8442"}
      member.emergency_contact.first_name.should == 'Emergency'
      member.emergency_contact.last_name.should == 'Contact'
      member.emergency_contact.address_1.should == 'Address 1'
      member.emergency_contact.address_2.should == 'Address 2'
      member.emergency_contact.address_3.should == 'Address 3'
      member.emergency_contact.address_4.should == 'Address 4'
      member.emergency_contact.postcode.should == 'Postcode'
      member.emergency_contact.phone_1.should == '01234 567890'
      member.emergency_contact.phone_2.should == '0987 654321'
      member.emergency_contact.email_1.should == 'emergency@example.com'
      member.emergency_contact.email_2.should == ''
      member.emergency_contact.custom.should == {"label_for_8443"=>"Data for 8443"}
      member.emergency_contact.custom_labels.should == {"label_for_8443"=>"Label for 8443"}
      member.doctor.first_name.should == 'Doctor'
      member.doctor.last_name.should == 'Contact'
      member.doctor.surgery.should == 'Surgery'
      member.doctor.address_1.should == 'Address 1'
      member.doctor.address_2.should == 'Address 2'
      member.doctor.address_3.should == 'Address 3'
      member.doctor.address_4.should == 'Address 4'
      member.doctor.postcode.should == 'Postcode'
      member.doctor.phone_1.should == '01234 567890'
      member.doctor.phone_2.should == '0987 654321'
      member.doctor.custom.should == {"label_for_8444"=>"Data for 8444"}
      member.doctor.custom_labels.should == {"label_for_8444"=>"Label for 8444"}
      member.valid?.should == true
    end

    it "Get from OSM (handles disabled contacts)" do
      body = {
        'status' => true,
        'error' => nil,
        'data' => {
          '123' => {
            'active' => true,
            'age' => '12 / 00',
            'date_of_birth' => '2000-03-08',
            'end_date' => '2010-06-03',
            'first_name' => 'John',
            'joined' => '2008-07-12',
            'last_name' => 'Smith',
            'member_id' => 123,
            'patrol' => 'Leaders',
            'patrol_id' => -2,
            'patrol_role_level' => 1,
            'patrol_role_level_label' => 'Assistant leader',
            'section_id' => 1,
            'started' => '2006-07-17',
            'custom_data' => {
              '5' => {'4848' => 'Data for 4848'},
              '7' => {'34' => 'Unspecified'},
            },
          }
        },
        'meta' => {
          'leader_count' => 20,
          'member_count' => 30,
          'status' => true,
          'structure' => [
            {'group_id' => 5, 'description' => 'This allows you to add  extra information for your members.', 'identifier' => 'customisable_data', 'name' => 'Customisable Data', 'columns' => [
              {'column_id' => 4848, 'group_column_id' => '5_4848', 'label' => 'Label for 4848', 'varname' => 'label_for_4848', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
            {'group_id' => 7, 'description' => '', 'identifier' => 'floating', 'name' => 'Floating', 'columns' => [
              {'column_id' => 34, 'group_column_id' => '7_34', 'label' => 'Gender', 'varname' => 'gender', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
          ],
        },
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/members/contact/grid/?action=getMembers", :body => body.to_json, :content_type => 'application/json')

      members = Osm::Member.get_for_section(@api, 1, 2)
      members.size.should == 1
      member = members[0]
      member.id.should == 123
      member.contact.should == nil
      member.primary_contact.should == nil
      member.secondary_contact.should == nil
      member.emergency_contact.should == nil
      member.doctor.should == nil
      member.valid?.should == true
    end

    it "Get from OSM (handles no custom data)" do
      body = {
        'status' => true,
        'error' => nil,
        'data' => {
          '123' => {
            'active' => true,
            'age' => '12 / 00',
            'date_of_birth' => '2000-03-08',
            'end_date' => '2010-06-03',
            'first_name' => 'John',
            'joined' => '2008-07-12',
            'last_name' => 'Smith',
            'member_id' => 123,
            'patrol' => 'Leaders',
            'patrol_id' => -2,
            'patrol_role_level' => 1,
            'patrol_role_level_label' => 'Assistant leader',
            'section_id' => 1,
            'started' => '2006-07-17',
            'custom_data' => {
              '7' => {'34' => 'Unspecified'},
            },
          }
        },
        'meta' => {
          'leader_count' => 20,
          'member_count' => 30,
          'status' => true,
          'structure' => [
            {'group_id' => 5, 'description' => 'This allows you to add  extra information for your members.', 'identifier' => 'customisable_data', 'name' => 'Customisable Data', 'columns' => [
              {'column_id' => 4848, 'group_column_id' => '5_4848', 'label' => 'Label for 4848', 'varname' => 'label_for_4848', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
            {'group_id' => 7, 'description' => '', 'identifier' => 'floating', 'name' => 'Floating', 'columns' => [
              {'column_id' => 34, 'group_column_id' => '7_34', 'label' => 'Gender', 'varname' => 'gender', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
          ],
        },
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/members/contact/grid/?action=getMembers", :body => body.to_json, :content_type => 'application/json')

      members = Osm::Member.get_for_section(@api, 1, 2)
      members.size.should == 1
      member = members[0]
      member.id.should == 123
      member.custom.should == {}
      member.valid?.should == true
    end

    it "Get from OSM (handles missing floating data)" do
      body = {
        'status' => true,
        'error' => nil,
        'data' => {
          '123' => {
            'active' => true,
            'age' => '12 / 00',
            'date_of_birth' => '2000-03-08',
            'end_date' => '2010-06-03',
            'first_name' => 'John',
            'joined' => '2008-07-12',
            'last_name' => 'Smith',
            'member_id' => 123,
            'patrol' => 'Leaders',
            'patrol_id' => -2,
            'patrol_role_level' => 1,
            'patrol_role_level_label' => 'Assistant leader',
            'section_id' => 1,
            'started' => '2006-07-17',
            'custom_data' => {
              '5' => {'4848' => 'Data for 4848'},
            },
          }
        },
        'meta' => {
          'leader_count' => 20,
          'member_count' => 30,
          'status' => true,
          'structure' => [
            {'group_id' => 5, 'description' => 'This allows you to add  extra information for your members.', 'identifier' => 'customisable_data', 'name' => 'Customisable Data', 'columns' => [
              {'column_id' => 4848, 'group_column_id' => '5_4848', 'label' => 'Label for 4848', 'varname' => 'label_for_4848', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
            {'group_id' => 7, 'description' => '', 'identifier' => 'floating', 'name' => 'Floating', 'columns' => [
              {'column_id' => 34, 'group_column_id' => '7_34', 'label' => 'Gender', 'varname' => 'gender', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120},
            ]},
          ],
        },
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/members/contact/grid/?action=getMembers", :body => body.to_json, :content_type => 'application/json')

      members = Osm::Member.get_for_section(@api, 1, 2)
      members.size.should == 1
      member = members[0]
      member.id.should == 123
      member.gender.should == nil
      member.valid?.should == true
    end


    it "Get from OSM (handles an empty data array)" do
      body = {
        'status' => true,
        'error' => nil,
        'data' => [],
        'meta' => {},
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/members/contact/grid/?action=getMembers", :body => body.to_json, :content_type => 'application/json')

      Osm::Member.get_for_section(@api, 1, 2).should == []
    end


    it "Create in OSM (succeded)" do
      member = Osm::Member.new(
        :section_id => 2,
        :first_name => 'First',
        :last_name => 'Last',
        :email1 => 'email1@example.com',
        :email2 => 'email2@example.com',
        :email3 => 'email3@example.com',
        :email4 => 'email4@example.com',
        :phone1 => '11111 111111',
        :phone2 => '222222',
        :phone3 => '+33 3333 333333',
        :phone4 => '4444 444 444',
        :address => '1 Some Road',
        :address2 => 'Address 2',
        :date_of_birth => '2000-01-02',
        :started => '2006-01-02',
        :joined => '2006-01-03',
        :parents => 'John and Jane Doe',
        :notes => 'None',
        :medical => 'Nothing',
        :religion => 'Unknown',
        :school => 'Some School',
        :ethnicity => 'Yes',
        :subs => 'Upto end of 2007',
        :custom1 => 'Custom Field 1',
        :custom2 => 'Custom Field 2',
        :custom3 => 'Custom Field 3',
        :custom4 => 'Custom Field 4',
        :custom5 => 'Custom Field 5',
        :custom6 => 'Custom Field 6',
        :custom7 => 'Custom Field 7',
        :custom8 => 'Custom Field 8',
        :custom9 => 'Custom Field 9',
        :grouping_id => '3',
        :grouping_leader => 0,
      )

      url = 'https://www.onlinescoutmanager.co.uk/users.php?action=newMember'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'sectionid' => 2,
        'firstname' => 'First',
        'lastname' => 'Last',
        'email1' => 'email1@example.com',
        'email2' => 'email2@example.com',
        'email3' => 'email3@example.com',
        'email4' => 'email4@example.com',
        'phone1' => '11111 111111',
        'phone2' => '222222',
        'phone3' => '+33 3333 333333',
        'phone4' => '4444 444 444',
        'address' => '1 Some Road',
        'address2' => 'Address 2',
        'dob' => '2000-01-02',
        'started' => '2006-01-02',
        'startedsection' => '2006-01-03',
        'parents' => 'John and Jane Doe',
        'notes' => 'None',
        'medical' => 'Nothing',
        'religion' => 'Unknown',
        'school' => 'Some School',
        'ethnicity' => 'Yes',
        'subs' => 'Upto end of 2007',
        'custom1' => 'Custom Field 1',
        'custom2' => 'Custom Field 2',
        'custom3' => 'Custom Field 3',
        'custom4' => 'Custom Field 4',
        'custom5' => 'Custom Field 5',
        'custom6' => 'Custom Field 6',
        'custom7' => 'Custom Field 7',
        'custom8' => 'Custom Field 8',
        'custom9' => 'Custom Field 9',
        'patrolid' => 3,
        'patrolleader' => 0,
      }

      Osm::Term.stub(:get_for_section) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":"ok","scoutid":1}'}) }
      member.create(@api).should == true
      member.id.should == 1
    end

    it "Create in OSM (failed)" do
      member = Osm::Member.new(
        :section_id => 2,
        :first_name => 'First',
        :last_name => 'Last',
        :date_of_birth => '2000-01-02',
        :started => '2006-01-02',
        :joined => '2006-01-03',
        :grouping_id => '3',
        :grouping_leader => 0,
      )

      HTTParty.should_receive(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":"ok","scoutid":-1}'}) }
      member.create(@api).should == false
    end


    it "Update in OSM (succeded)" do
      member = Osm::Member.new()
      member.id = 1
      member.section_id = 2
      member.first_name = 'First'
      member.last_name = 'Last'
      member.email1 = 'email1@example.com'
      member.email2 = 'email2@example.com'
      member.email3 = 'email3@example.com'
      member.email4 = 'email4@example.com'
      member.phone1 = '11111 111111'
      member.phone2 = '222222'
      member.phone3 = '+33 3333 333333'
      member.phone4 = '4444 444 444'
      member.address = '1 Some Road'
      member.address2 = 'Address 2'
      member.date_of_birth = '2000-01-02'
      member.started = '2006-01-02'
      member.joined = '2006-01-03'
      member.parents = 'John and Jane Doe'
      member.notes = 'None'
      member.medical = 'Nothing'
      member.religion = 'Unknown'
      member.school = 'Some School'
      member.ethnicity = 'Yes'
      member.subs = 'Upto end of 2007'
      member.custom1 = 'Custom Field 1'
      member.custom2 = 'Custom Field 2'
      member.custom3 = 'Custom Field 3'
      member.custom4 = 'Custom Field 4'
      member.custom5 = 'Custom Field 5'
      member.custom6 = 'Custom Field 6'
      member.custom7 = 'Custom Field 7'
      member.custom8 = 'Custom Field 8'
      member.custom9 = 'Custom Field 9'
      member.grouping_id = 3
      member.grouping_leader = 0

      url = 'https://www.onlinescoutmanager.co.uk/users.php?action=updateMember&dateFormat=generic'
      body_data = {
        'firstname' => 'First',
        'lastname' => 'Last',
        'email1' => 'email1@example.com',
        'email2' => 'email2@example.com',
        'email3' => 'email3@example.com',
        'email4' => 'email4@example.com',
        'phone1' => '11111 111111',
        'phone2' => '222222',
        'phone3' => '+33 3333 333333',
        'phone4' => '4444 444 444',
        'address' => '1 Some Road',
        'address2' => 'Address 2',
        'dob' => '2000-01-02',
        'started' => '2006-01-02',
        'startedsection' => '2006-01-03',
        'parents' => 'John and Jane Doe',
        'notes' => 'None',
        'medical' => 'Nothing',
        'religion' => 'Unknown',
        'school' => 'Some School',
        'ethnicity' => 'Yes',
        'subs' => 'Upto end of 2007',
        'custom1' => 'Custom Field 1',
        'custom2' => 'Custom Field 2',
        'custom3' => 'Custom Field 3',
        'custom4' => 'Custom Field 4',
        'custom5' => 'Custom Field 5',
        'custom6' => 'Custom Field 6',
        'custom7' => 'Custom Field 7',
        'custom8' => 'Custom Field 8',
        'custom9' => 'Custom Field 9',
        'patrolid' => 3,
        'patrolleader' => 0,
      }
      body = (body_data.inject({}) {|h,(k,v)| h[k]=v.to_s; h}).to_json

      body_data.each do |column, value|
        unless ['patrolid', 'patrolleader'].include?(column)
          HTTParty.should_receive(:post).with(url, {:body => {
            'apiid' => @CONFIGURATION[:api][:osm][:id],
            'token' => @CONFIGURATION[:api][:osm][:token],
            'userid' => 'user_id',
            'secret' => 'secret',
            'scoutid' => member.id,
            'column' => column,
            'value' => value,
            'sectionid' => member.section_id,
          }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>body}) }
        end
      end

    end


    describe "Update in OSM" do

      before :each do
        attributes = {
          :id => 1,
          :section_id => 2,
          :first_name => 'First',
          :last_name => 'Last',
          :date_of_birth => '2000-01-02',
          :grouping_id => '3',
          :grouping_leader => 0,
          :grouping_label => 'Grouping',
          :grouping_leader_label => '6er',
          :age => '06 / 07',
          :gender => :other,
          :joined_movement => '2006-01-02',
          :started_section => '2006-01-07',
          :finished_section => '2007-12-31',
          :custom => DirtyHashy[ '12_3' => '123' ],
          :custom_labels => {'12_3' => 'Label for 123'},
          :contact => Osm::Member::MemberContact.new(postcode: 'A'),
          :primary_contact => Osm::Member::PrimaryContact.new(postcode: 'B'),
          :secondary_contact => Osm::Member::SecondaryContact.new(postcode: 'C'),
          :emergency_contact => Osm::Member::EmergencyContact.new(postcode: 'D'),
          :doctor => Osm::Member::DoctorContact.new(postcode: 'E'),
        }
        @member = Osm::Member.new(attributes)
      end

      it "Only updated fields" do
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/members/contact/?action=update', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "sectionid" => 2,
          "scoutid" => 1,
          "column" => "firstname",
          "value" => "John",
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"ok":true}'}) }

        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/members/contact/?action=update', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "context" => "members",
          "associated_type" => "member",
          "associated_id" => 1,
          "group_id" => 7,
          "column_id" => 34,
          "value" => "Unspecified",
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"data":{"value":"Unspecified"}}'}) }

        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/customdata/?action=update&section_id=2', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "context" => "members",
          "associated_type" => "member",
          "associated_id" => 1,
          "group_id" => 6,
          "data[address1]" => "Address 1",
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"status":true}'}) }
        
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/customdata/?action=update&section_id=2', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "context" => "members",
          "associated_type" => "member",
          "associated_id" => 1,
          "group_id" => 1,
          "data[address2]" => "Address 2",
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"status":true}'}) }

        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/customdata/?action=update&section_id=2', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "context" => "members",
          "associated_type" => "member",
          "associated_id" => 1,
          "group_id" => 2,
          "data[address3]" => "Address 3",
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"status":true}'}) }

        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/customdata/?action=update&section_id=2', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "context" => "members",
          "associated_type" => "member",
          "associated_id" => 1,
          "group_id" => 3,
          "data[address4]" => "Address 4",
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"status":true}'}) }

        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/customdata/?action=update&section_id=2', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "context" => "members",
          "associated_type" => "member",
          "associated_id" => 1,
          "group_id" => 4,
          "data[surgery]" => "Surgery",
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"status":true}'}) }

        Osm::Term.stub(:get_for_section) { [] }

        @member.first_name = 'John'
        @member.gender = :unspecified
        @member.contact.address_1 = 'Address 1'
        @member.primary_contact.address_2 = 'Address 2'
        @member.secondary_contact.address_3 = 'Address 3'
        @member.emergency_contact.address_4 = 'Address 4'
        @member.doctor.surgery = 'Surgery'
        @member.update(@api).should == true
      end

      it "All fields" do
        {'firstname'=>'First', 'lastname'=>'Last', 'patrolid'=>3, 'patrolleader'=>0, 'dob'=>'2000-01-02', 'startedsection'=>'2006-01-07', 'started'=>'2006-01-02'}.each do |key, value|
          HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/members/contact/?action=update', {:body => {
            "apiid" => "1",
            "token" => "API TOKEN",
            "userid" => "user_id",
            "secret" => "secret",
            "sectionid" => 2,
            "scoutid" => 1,
            "column" => key,
            "value" => value,
          }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"ok":true}'}) }
        end

        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/members/contact/?action=update', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "context" => "members",
          "associated_type" => "member",
          "associated_id" => 1,
          "group_id" => 7,
          "column_id" => 34,
          "value" => "Other",
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"data":{"value":"Other"}}'}) }

        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/customdata/?action=updateColumn&section_id=2', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "context" => "members",
          "associated_type" => "member",
          "associated_id" => 1,
          "group_id" => 5,
          "column_id" => "12_3",
          "value" => "123",
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"data":{"value":"123"}}'}) }

        {6=>'A', 1=>'B', 2=>'C'}.each do |group_id, postcode|
          HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/customdata/?action=update&section_id=2', {:body => {
            "apiid" => "1",
            "token" => "API TOKEN",
            "userid" => "user_id",
            "secret" => "secret",
            "context" => "members",
            "associated_type" => "member",
            "associated_id" => 1,
            "group_id" => group_id,
            "data[firstname]" => nil,
            "data[lastname]" => nil,
            "data[address1]" => nil,
            "data[address2]" => nil,
            "data[address3]" => nil,
            "data[address4]" => nil,
            "data[postcode]" => postcode,
            "data[phone1]" => nil,
            "data[phone2]" => nil,
            "data[email1]" => nil,
            "data[email1_leaders]" => false,
            "data[email2]" => nil,
            "data[email2_leaders]" => false,
            "data[phone1_sms]" => false,
            "data[phone2_sms]" => false,
          }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"status":true}'}) }
        end

        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/customdata/?action=update&section_id=2', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "context" => "members",
          "associated_type" => "member",
          "associated_id" => 1,
          "group_id" => 3,
          "data[firstname]" => nil,
          "data[lastname]" => nil,
          "data[address1]" => nil,
          "data[address2]" => nil,
          "data[address3]" => nil,
          "data[address4]" => nil,
          "data[postcode]" => "D",
          "data[phone1]" => nil,
          "data[phone2]" => nil,
          "data[email1]" => nil,
          "data[email2]" => nil,
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"status":true}'}) }

        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/customdata/?action=update&section_id=2', {:body => {
          "apiid" => "1",
          "token" => "API TOKEN",
          "userid" => "user_id",
          "secret" => "secret",
          "context" => "members",
          "associated_type" => "member",
          "associated_id" => 1,
          "group_id" => 4,
          "data[firstname]" => nil,
          "data[lastname]" => nil,
          "data[surgery]" => nil,
          "data[address1]" => nil,
          "data[address2]" => nil,
          "data[address3]" => nil,
          "data[address4]" => nil,
          "data[postcode]" => "E",
          "data[phone1]" => nil,
          "data[phone2]" => nil,
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"status":true}'}) }

        Osm::Term.stub(:get_for_section) { [] }

        @member.update(@api, true).should == true
      end

      it "Failed to update in OSM" do
        @member.first_name = 'John'
        HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{}'}) }
        @member.update(@api).should == false
      end

      it "Raises error if member is invalid" do
        expect{ Osm::Member.new.create(@api) }.to raise_error(Osm::ObjectIsInvalid, 'member is invalid')
      end

    end

    it "Get Photo link" do
      member = Osm::Member.new(
        :id => 1,
        :section_id => 2,
        :first_name => 'First',
        :last_name => 'Last',
        :date_of_birth => '2000-01-02',
        :started_section => '2006-01-02',
        :joined_movement => '2006-01-03',
        :grouping_id => '3',
        :grouping_leader => 0,
        :grouping_label => 'Grouping',
        :grouping_leader_label => '',
        :custom => {},
        :custom_labels => {},
        :contact => Osm::Member::MemberContact.new(),
        :primary_contact => Osm::Member::PrimaryContact.new(),
        :secondary_contact => Osm::Member::PrimaryContact.new(),
        :emergency_contact => Osm::Member::EmergencyContact.new(),
        :doctor => Osm::Member::DoctorContact.new(),
      )
      HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :content_type=>'image/jpeg', :body=>'abcdef'}) }

      member.get_photo(@api).should == "abcdef"
    end


    describe "Get My.SCOUT link" do

      before :each do
        @member = Osm::Member.new(
          :id => 1,
          :section_id => 2,
          :first_name => 'First',
          :last_name => 'Last',
          :date_of_birth => '2000-01-02',
          :started_section => '2006-01-02',
          :joined_movement => '2006-01-03',
          :grouping_id => '3',
          :grouping_leader => 0,
          :grouping_label => 'Grouping',
          :grouping_leader_label => '',
          :custom => {},
          :custom_labels => {},
          :contact => Osm::Member::MemberContact.new(),
          :primary_contact => Osm::Member::PrimaryContact.new(),
          :secondary_contact => Osm::Member::PrimaryContact.new(),
          :emergency_contact => Osm::Member::EmergencyContact.new(),
          :doctor => Osm::Member::DoctorContact.new(),
        )
      end

      it "Get the key" do
        url = 'https://www.onlinescoutmanager.co.uk/api.php?action=getMyScoutKey&sectionid=2&scoutid=1'
        HTTParty.should_receive(:post).with(url, {:body => {
          'apiid' => @CONFIGURATION[:api][:osm][:id],
          'token' => @CONFIGURATION[:api][:osm][:token],
          'userid' => 'user_id',
          'secret' => 'secret',
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"ok":true,"key":"KEY-HERE"}'}) }

        @member.myscout_link_key(@api).should == 'KEY-HERE'
      end

      it "Default" do
        @member.stub(:myscout_link_key) { 'KEY-HERE' }
        @member.myscout_link(@api).should == 'https://www.onlinescoutmanager.co.uk/parents/badges.php?sc=1&se=2&c=KEY-HERE'
      end

      it "Payments" do
        @member.stub(:myscout_link_key) { 'KEY-HERE' }
        @member.myscout_link(@api, :payments).should == 'https://www.onlinescoutmanager.co.uk/parents/payments.php?sc=1&se=2&c=KEY-HERE'
      end

      it "Events" do
        @member.stub(:myscout_link_key) { 'KEY-HERE' }
        @member.myscout_link(@api, :events).should == 'https://www.onlinescoutmanager.co.uk/parents/events.php?sc=1&se=2&c=KEY-HERE'
      end

      it "Specific Event" do
        @member.stub(:myscout_link_key) { 'KEY-HERE' }
        @member.myscout_link(@api, :events, 2).should == 'https://www.onlinescoutmanager.co.uk/parents/events.php?sc=1&se=2&c=KEY-HERE&e=2'
      end

      it "Programme" do
        @member.stub(:myscout_link_key) { 'KEY-HERE' }
        @member.myscout_link(@api, :programme).should == 'https://www.onlinescoutmanager.co.uk/parents/programme.php?sc=1&se=2&c=KEY-HERE'
      end

      it "Badges" do
        @member.stub(:myscout_link_key) { 'KEY-HERE' }
        @member.myscout_link(@api, :badges).should == 'https://www.onlinescoutmanager.co.uk/parents/badges.php?sc=1&se=2&c=KEY-HERE'
      end

      it "Notice board" do
        @member.stub(:myscout_link_key) { 'KEY-HERE' }
        @member.myscout_link(@api, :notice).should == 'https://www.onlinescoutmanager.co.uk/parents/notice.php?sc=1&se=2&c=KEY-HERE'
      end

      it "Personal details" do
        @member.stub(:myscout_link_key) { 'KEY-HERE' }
        @member.myscout_link(@api, :details).should == 'https://www.onlinescoutmanager.co.uk/parents/details.php?sc=1&se=2&c=KEY-HERE'
      end

      it "Census detail entry" do
        @member.stub(:myscout_link_key) { 'KEY-HERE' }
        @member.myscout_link(@api, :census).should == 'https://www.onlinescoutmanager.co.uk/parents/census.php?sc=1&se=2&c=KEY-HERE'
      end

      it "Gift Aid consent" do
        @member.stub(:myscout_link_key) { 'KEY-HERE' }
        @member.myscout_link(@api, :giftaid).should == 'https://www.onlinescoutmanager.co.uk/parents/giftaid.php?sc=1&se=2&c=KEY-HERE'
      end

    end

  end

end
