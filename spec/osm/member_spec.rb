# encoding: utf-8
require 'spec_helper'

describe "Member" do

  it "Create" do
    attributes = {
      :id => 1,
      :section_id => 2,
      :type => '',
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
      :address2 => '',
      :date_of_birth => '2000-01-02',
      :started => '2006-01-02',
      :joining_in_years => '2',
      :parents => 'John and Jane Doe',
      :notes => 'None',
      :medical => 'Nothing',
      :religion => 'Unknown',
      :school=> 'Some School',
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
      :joined => '2006-01-07',
      :age => '06/07',
      :joined_years => 1,
    }
    member = Osm::Member.new(attributes)

    member.id.should == 1
    member.section_id.should == 2
    member.type.should == ''
    member.first_name.should == 'First'
    member.last_name.should == 'Last'
    member.email1.should == 'email1@example.com'
    member.email2.should == 'email2@example.com'
    member.email3.should == 'email3@example.com'
    member.email4.should == 'email4@example.com'
    member.phone1.should == '11111 111111'
    member.phone2.should == '222222'
    member.phone3.should == '+33 3333 333333'
    member.phone4.should == '4444 444 444'
    member.address.should == '1 Some Road'
    member.address2.should == ''
    member.date_of_birth.should == Date.new(2000, 1, 2)
    member.started.should == Date.new(2006, 1, 2)
    member.joining_in_years.should == 2
    member.parents.should == 'John and Jane Doe'
    member.notes.should == 'None'
    member.medical.should == 'Nothing'
    member.religion.should == 'Unknown'
    member.school.should == 'Some School'
    member.ethnicity.should == 'Yes'
    member.subs.should == 'Upto end of 2007'
    member.custom1.should == 'Custom Field 1'
    member.custom2.should == 'Custom Field 2'
    member.custom3.should == 'Custom Field 3'
    member.custom4.should == 'Custom Field 4'
    member.custom5.should == 'Custom Field 5'
    member.custom6.should == 'Custom Field 6'
    member.custom7.should == 'Custom Field 7'
    member.custom8.should == 'Custom Field 8'
    member.custom9.should == 'Custom Field 9'
    member.grouping_id.should == 3
    member.grouping_leader.should == 0
    member.joined.should == Date.new(2006, 1, 7)
    member.age.should == '06/07'
    member.joined_years.should == 1
    member.valid?.should be_true
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


  it "Provides each part of age" do
    data = {
      :age => '06/07',
    }
    member = Osm::Member.new(data)

    member.age_years.should == 6
    member.age_months.should == 7
  end


  describe "Using the API" do

    it "Create from API data" do
      body = {
        'identifier' => 'scoutid',
        'items' => [{
          'scoutid' => 1,
          'sectionidO' => 2,
          'type' => '',
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
          'address2' => '',
          'dob' => '2000-01-02',
          'started' => '2006-01-02',
          'joining_in_yrs' => '2',
          'parents' => 'John and Jane Doe',
          'notes' => 'None',
          'medical' => 'Nothing',
          'religion' => 'Unknown',
          'school'=> 'Some School',
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
          'patrolid' => '3',
          'patrolleader' => 0,
          'joined' => '2006-01-07',
          'age' => '06/07',
          'yrs' => 1,
          'patrol' => 'Blue',
          'patrolidO' => '4',
          'patrolleaderO' => 0,
        }]
      }

      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=getUserDetails&sectionid=1&termid=2", :body => body.to_json)
      members = Osm::Member.get_for_section(@api, 1, 2)
      members.size.should == 1
      members[0].id.should == 1
    end

  end

end