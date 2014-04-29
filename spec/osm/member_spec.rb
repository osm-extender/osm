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

  it "Tells if member is a leader" do
    Osm::Member.new(grouping_id: -2).leader?.should be_true  # In the leader grouping
    Osm::Member.new(grouping_id: 2).leader?.should be_false  # In a youth grouping
    Osm::Member.new(grouping_id: 0).leader?.should be_false  # Not in a grouping
  end

  it "Tells if member is a youth member" do
    Osm::Member.new(grouping_id: -2).youth?.should be_false  # In the leader grouping
    Osm::Member.new(grouping_id: 2).youth?.should be_true  # In a youth grouping
    Osm::Member.new(grouping_id: 0).youth?.should be_false  # Not in a grouping
  end

  it "Provides each part of age" do
    data = {
      :age => '06/07',
    }
    member = Osm::Member.new(data)

    member.age_years.should == 6
    member.age_months.should == 7
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

    it "Create from API data" do
      body = [
        {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"column_names\":\"names\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"fields\":true},\"intouch\":{\"intouch_fields\":true},\"mobFields\":{\"mobile_fields\":true}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"1", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>10, "member"=>20, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
      ]
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json, :content_type => 'application/json')

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
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=getUserDetails&sectionid=1&termid=2", :body => body.to_json, :content_type => 'application/json')

      body = {'items' => [{'scoutid'=>'1', 'pic'=>true}]}
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/members/contact/?action=getListOfMembers&sort=patrolid&sectionid=1&termid=2&section=beavers", :body => body.to_json, :content_type => 'application/json') 

      members = Osm::Member.get_for_section(@api, 1, 2)
      members.size.should == 1
      members[0].id.should == 1
    end

    it "Create from API data (Waiting list)" do
      body = [
        {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"waiting\",\"columnNames\":{\"column_names\":\"names\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"fields\":true},\"intouch\":{\"intouch_fields\":true},\"mobFields\":{\"mobile_fields\":true}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"1", "sectionname"=>"Section 1", "section"=>"waiting", "isDefault"=>"1", "permissions"=>{"badge"=>10, "member"=>20, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
      ]
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json, :content_type => 'application/json')

      body = {
        'identifier' => 'scoutid',
        'items' => []
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=getUserDetails&sectionid=1&termid=-1", :body => body.to_json, :content_type => 'application/json')

      body = {'items' => [{'scoutid'=>'1', 'pic'=>true}]}
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/members/contact/?action=getListOfMembers&sort=patrolid&sectionid=1&termid=-1&section=waiting", :body => body.to_json, :content_type => 'application/json')

      members = Osm::Member.get_for_section(@api, 1, 2)
      members.size.should == 0
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
      member.create(@api).should be_true
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
      member.create(@api).should be_false
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
      HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/users.php?action=updateMemberPatrol', {:body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'scoutid' => member.id,
        'patrolid' => member.grouping_id,
        'pl' => member.grouping_leader,
        'sectionid' => member.section_id,
      }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>body}) }
      Osm::Term.stub(:get_for_section) { [] }

      member.update(@api).should be_true
    end

    it "Update in OSM (only updated fields)" do
      member = Osm::Member.new(
        :id => 1,
        :section_id => 2,
        :date_of_birth => '2000-01-02',
        :started => '2006-01-02',
        :joined => '2006-01-03',
        :grouping_leader => 0,
      )
      member.first_name = 'First'
      member.last_name = 'Last'
      member.grouping_id = 3

      url = 'https://www.onlinescoutmanager.co.uk/users.php?action=updateMember&dateFormat=generic'
      body_data = {
        'firstname' => 'First',
        'lastname' => 'Last',
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
      HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/users.php?action=updateMemberPatrol', {:body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'scoutid' => member.id,
        'patrolid' => member.grouping_id,
        'pl' => member.grouping_leader,
        'sectionid' => member.section_id,
      }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>body}) }
      Osm::Term.stub(:get_for_section) { [] }

      member.update(@api).should be_true
    end

    it "Update in OSM (failed)" do
      member = Osm::Member.new(
        :id => 1,
        :section_id => 2,
        :last_name => 'Last',
        :date_of_birth => '2000-01-02',
        :started => '2006-01-02',
        :joined => '2006-01-03',
        :grouping_id => '3',
        :grouping_leader => 0,
      )
      member.first_name = 'First'

      HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{}'}) }
      member.update(@api).should be_false
    end

    it "Get Photo link" do
      member = Osm::Member.new(
        :id => 1,
        :section_id => 2,
        :first_name => 'First',
        :last_name => 'Last',
        :date_of_birth => '2000-01-02',
        :started => '2006-01-02',
        :joined => '2006-01-03',
        :grouping_id => '3',
        :grouping_leader => 0,
        :has_photo => true,
      )
      HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :content_type=>'image/jpeg', :body=>'abcdef'}) }

      member.get_photo(@api).should == "abcdef"
    end

    it "Get Photo link when no photo uploaded" do
      member = Osm::Member.new(
        :id => 1,
        :section_id => 2,
        :first_name => 'First',
        :last_name => 'Last',
        :date_of_birth => '2000-01-02',
        :started => '2006-01-02',
        :joined => '2006-01-03',
        :grouping_id => '3',
        :grouping_leader => 0,
        :has_photo => false,
      )

      expect{ member.get_photo(@api) }.to raise_error(Osm::Error, "the member doesn't have a photo in OSM")
    end

    describe "Get My.SCOUT link" do

      before :each do
        @member = Osm::Member.new(
          :id => 1,
          :section_id => 2,
          :first_name => 'First',
          :last_name => 'Last',
          :date_of_birth => '2000-01-02',
          :started => '2006-01-02',
          :joined => '2006-01-03',
          :grouping_id => '3',
          :grouping_leader => 0,
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

    end

  end

end
