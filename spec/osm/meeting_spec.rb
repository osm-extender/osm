# encoding: utf-8
require 'spec_helper'
require 'date'

describe "Meeting" do

  it "Create" do
    e = Osm::Meeting.new(
      :id => 1,
      :section_id => 2,
      :title => 'Meeting Name',
      :notes_for_parents => 'Notes for parents',
      :games => 'Games',
      :pre_notes => 'Before',
      :post_notes => 'After',
      :leaders => 'Leaders',
      :start_time => '19:00',
      :finish_time => '21:00',
      :date => Date.new(2000, 01, 02),
      :activities => [],
      :badge_links => []
    )

    e.id.should == 1
    e.section_id.should == 2
    e.title.should == 'Meeting Name'
    e.notes_for_parents.should == 'Notes for parents'
    e.games.should == 'Games'
    e.pre_notes.should == 'Before'
    e.post_notes.should == 'After'
    e.leaders.should == 'Leaders'
    e.start_time.should == '19:00'
    e.finish_time.should == '21:00'
    e.date.should == Date.new(2000, 1, 2)
    e.activities.should == []
    e.badge_links.should == []
    e.valid?.should be_true
  end

  it "Sorts by Section ID, Meeting date, Start time and then Meeting ID" do
    meeting1 = Osm::Meeting.new(:section_id => 1, :id => 1, :date => (Date.today - 1), :start_time => '18:00')
    meeting2 = Osm::Meeting.new(:section_id => 2, :id => 1, :date => (Date.today - 1), :start_time => '18:00')
    meeting3 = Osm::Meeting.new(:section_id => 2, :id => 1, :date => (Date.today + 1), :start_time => '18:00')
    meeting4 = Osm::Meeting.new(:section_id => 2, :id => 1, :date => (Date.today + 1), :start_time => '19:00')
    meeting5 = Osm::Meeting.new(:section_id => 2, :id => 2, :date => (Date.today + 1), :start_time => '19:00')

    data = [meeting5, meeting3, meeting2, meeting4, meeting1]
    data.sort.should == [meeting1, meeting2, meeting3, meeting4, meeting5]
  end


  describe "Meeting::Activity" do

    it "Create" do
      ea = Osm::Meeting::Activity.new(
        :activity_id => 2,
        :title => 'Activity Name',
        :notes => 'Notes',
      )

      ea.activity_id.should == 2
      ea.title.should == 'Activity Name'
      ea.notes.should == 'Notes'
      ea.valid?.should be_true
    end

    it "Sorts by title then activity_id" do
      a1 = Osm::Meeting::Activity.new(:title => 'a', :activity_id => 1)
      a2 = Osm::Meeting::Activity.new(:title => 'b', :activity_id => 1)
      a3 = Osm::Meeting::Activity.new(:title => 'b', :activity_id => 2)

      data = [a2, a3, a1]
      data.sort.should == [a1, a2, a3]
    end

  end


  describe 'Using the API' do

    it "Fetch the term's programme for a section" do
      body = {
        "items" => [{"eveningid" => "5", "sectionid" =>"3", "title" => "Weekly Meeting 1", "notesforparents" => "parents", "games" => "games", "prenotes" => "before", "postnotes" => "after", "leaders" => "leaders", "meetingdate" => "2001-02-03", "starttime" => "19:15:00", "endtime" => "20:30:00", "googlecalendar" => ""}],
        "activities" => {"5" => [
          {"activityid" => "6", "title" => "Activity 6", "notes" => "Some notes", "eveningid" => "5"},
          {"activityid" => "7", "title" => "Activity 7", "notes" => "", "eveningid" => "5"}
        ]},
        "badgelinks" => {"5" => [{
          'badge' => 'artist',
          'badgeLongName' => 'Artist',
          'badge_id' => '180',
          'badge_version' => '0',
          'badgetype' => 'activity',
          'badgetypeLongName' => 'Activity',
          'column_id' => '1234',
          'columnname' => '1234',
          'columnnameLongName' => 'Guide Dogs',
          'data' => '',
          'label' => 'Disability Awareness Activity Guide dogs',
          'section' => 'cubs',
          'sectionLongName' => 'Cubs',
         }]},
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/programme.php?action=getProgramme&sectionid=3&termid=4", :body => body.to_json, :content_type => 'application/json')

      programme = Osm::Meeting.get_for_section(@api, 3, 4)
      programme.size.should == 1
      meeting = programme[0]
      meeting.is_a?(Osm::Meeting).should be_true
      meeting.id.should == 5
      meeting.section_id.should == 3
      meeting.title.should == 'Weekly Meeting 1'
      meeting.notes_for_parents.should == 'parents'
      meeting.games.should == 'games'
      meeting.pre_notes.should == 'before'
      meeting.post_notes.should == 'after'
      meeting.leaders.should == 'leaders'
      meeting.date.should == Date.new(2001, 2, 3)
      meeting.start_time.should == '19:15'
      meeting.finish_time.should == '20:30'
      meeting.activities.size.should == 2
      activity = meeting.activities[0]
      activity.activity_id.should == 6
      activity.title.should == 'Activity 6'
      activity.notes.should == 'Some notes'
      meeting.badge_links.size.should == 1
      badge_link = meeting.badge_links[0]
      badge_link.badge_type.should == :activity
      badge_link.badge_section.should == :cubs
      badge_link.badge_name.should == 'Artist'
      badge_link.badge_id.should == 180
      badge_link.badge_version.should == 0
      badge_link.requirement_id.should == 1234
      badge_link.requirement_label.should == 'Guide Dogs'
      badge_link.data.should == ''
    end

    it "Fetch badge requirements for a meeting (from API)" do
      Osm::Model.stub('has_permission?').and_return(true)
      badges_body = [{'a'=>'a'},{'a'=>'A'}]
      FakeWeb.register_uri(:post, 'https://www.onlinescoutmanager.co.uk/users.php?action=getActivityRequirements&date=2000-01-02&sectionid=3&section=cubs', :body => badges_body.to_json, :content_type => 'application/json')
      roles_body = [
        {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"cubs\",\"columnNames\":{\"column_names\":\"names\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"fields\":true},\"intouch\":{\"intouch_fields\":true},\"mobFields\":{\"mobile_fields\":true}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"3", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>100, "member"=>20, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
      ]
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => roles_body.to_json, :content_type => 'application/json')

      meeting = Osm::Meeting.new(:date => Date.new(2000, 1, 2), :section_id => 3)
      meeting.get_badge_requirements(@api).should == badges_body
    end

    it "Fetch badge requirements for a meeting (iterating through activities)" do
      Osm::Model.stub('has_permission?').with(@api, :write, :badge, 3, {}).and_return(false)
      roles_body = [
        {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"cubs\",\"columnNames\":{\"column_names\":\"names\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"fields\":true},\"intouch\":{\"intouch_fields\":true},\"mobFields\":{\"mobile_fields\":true}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"3", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>10, "member"=>20, "user"=>100, "register"=>100, "contact"=>100, "programme"=>10, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
      ]
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => roles_body.to_json, :content_type => 'application/json')

      Osm::Activity.stub(:get) { Osm::Activity.new(:badges => [
        Osm::Activity::Badge.new(badge_type: :activity, badge_section: :beavers, requirement_label: 'label', data: 'data', badge_name: 'badge', badge_id: 2, badge_version: 0, requirement_id: 200)
      ]) }
  
      meeting = Osm::Meeting.new(
        :id => 2,
        :date => Date.new(2000, 1, 2),
        :section_id => 3,
        :activities => [Osm::Meeting::Activity.new(:activity_id => 4)],
        :badge_links => [
          Osm::Activity::Badge.new(badge_type: :activity, badge_section: :beavers, requirement_label: 'label 2', data: 'data 2', badge_name: 'badge 2', badge_id: 4, badge_version: 1, requirement_id: 400)
        ],
      )

      meeting.get_badge_requirements(@api).should == [
        {"badge"=>nil, "badge_id"=>4, "badge_version"=>1, "column_id"=>400, "badgeName"=>"badge 2", "badgetype"=>:activity, "columngroup"=>nil, "columnname"=>nil, "data"=>"data 2", "eveningid"=>2, "meetingdate"=>Date.new(2000, 1, 2), "name"=>"label 2", "section"=>:beavers, "sectionid"=>3},
        {"badge"=>nil, "badge_id"=>2, "badge_version"=>0, "column_id"=>200, "badgeName"=>"badge", "badgetype"=>:activity, "columngroup"=>nil, "columnname"=>nil, "data"=>"data", "eveningid"=>2, "meetingdate"=>Date.new(2000, 1, 2), "name"=>"label", "section"=>:beavers, "sectionid"=>3}
      ]
    end

    it "Create a meeting (succeded)" do
      url = 'https://www.onlinescoutmanager.co.uk/programme.php?action=addActivityToProgramme'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'meetingdate' => '2000-01-02',
        'sectionid' => 1,
        'activityid' => -1,
        'start' => '2000-01-02',
        'starttime' => '11:11',
        'endtime' => '22:22',
        'title' => 'Title',
      }

      Osm::Term.stub(:get_for_section) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":0}'}) }
      Osm::Meeting.create(@api, {
        :section_id => 1,
        :date => Date.new(2000, 1, 2),
        :start_time => '11:11',
        :finish_time => '22:22',
        :title => 'Title',
      }).is_a?(Osm::Meeting).should be_true
    end

    it "Create a meeting (failed)" do
      Osm::Term.stub(:get_for_section) { [] }
      HTTParty.should_receive(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'[]'}) }
      Osm::Meeting.create(@api, {
        :section_id => 1,
        :date => Date.new(2000, 1, 2),
        :start_time => '11:11',
        :finish_time => '22:22',
        :title => 'Title',
      }).should be_nil
    end


    it "Add activity to meeting (succeded)" do
      url = 'https://www.onlinescoutmanager.co.uk/programme.php?action=addActivityToProgramme'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'meetingdate' => '2000-01-02',
        'sectionid' => 1,
        'activityid' => 2,
        'notes' => 'Notes',
      }

      Osm::Term.stub(:get_for_section) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":0}'}) }
      activity = Osm::Activity.new(:id => 2, :title => 'Title')
      meeting = Osm::Meeting.new(:section_id => 1, :date => Date.new(2000, 1, 2))
      meeting.add_activity(@api, activity, 'Notes').should be_true
      meeting.activities[0].activity_id.should == 2
    end

    it "Add activity to meeting (failed)" do
      HTTParty.should_receive(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":1}'}) }
      activity = Osm::Activity.new(:id => 2, :title => 'Title')
      meeting = Osm::Meeting.new(:section_id => 1, :date => Date.new(2000, 1, 2))
      meeting.add_activity(@api, activity, 'Notes').should be_false
    end


    it "Update a meeting (succeded)" do
      url = 'https://www.onlinescoutmanager.co.uk/programme.php?action=editEvening'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'eveningid' => 1, 'sectionid' => 2, 'meetingdate' => '2000-01-02', 'starttime' => nil,
        'endtime' => nil, 'title' => 'Unnamed meeting', 'notesforparents' =>'', 'prenotes' => '',
        'postnotes' => '', 'games' => '', 'leaders' => '',
        'activity' => '[{"activityid":3,"notes":"Some notes"}]',
        'badgelinks' => '[{"badge_id":"181","badge_version":"0","column_id":"93384","badge":null,"badgeLongName":"Badge name","columnname":null,"columnnameLongName":"l","data":"","section":"beavers","sectionLongName":null,"badgetype":"activity","badgetypeLongName":null}]',
      }
      Osm::Term.stub(:get_for_section) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":0}'}) }

      meeting = Osm::Meeting.new(
        :id=>1,
        :section_id=>2,
        :date=>Date.new(2000, 01, 02),
        :activities => [Osm::Meeting::Activity.new(:activity_id => 3, :title => 'Activity Title', :notes => 'Some notes')],
        :badge_links => [Osm::Meeting::BadgeLink.new(
          :badge_type => :activity,
          :badge_section => :beavers,
          :requirement_label => 'l',
          :data => '',
          :badge_name => 'Badge name',
          :badge_id => 181,
          :badge_version => 0,
          :requirement_id => 93384,
        )]
      )
      meeting.update(@api).should be_true
    end

    it "Update a meeting (failed)" do
      url = 'https://www.onlinescoutmanager.co.uk/programme.php?action=editEvening'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'eveningid' => 1, 'sectionid' => 2, 'meetingdate' => '2000-01-02', 'starttime' => nil,
        'endtime' => nil, 'title' => 'Unnamed meeting', 'notesforparents' =>'', 'prenotes' => '',
        'postnotes' => '', 'games' => '', 'leaders' => '', 'activity' => '[]', 'badgelinks' => '[]',
      }
      Osm::Term.stub(:get_for_section) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":1}'}) }

      meeting = Osm::Meeting.new(:id=>1, :section_id=>2, :date=>Date.new(2000, 01, 02))
      meeting.update(@api).should be_false
    end

    it "Update a meeting (invalid meeting)" do
      meeting = Osm::Meeting.new
      expect{ meeting.update(@api) }.to raise_error(Osm::ObjectIsInvalid)
    end


    it "Delete a meeting" do
      url = 'https://www.onlinescoutmanager.co.uk/programme.php?action=deleteEvening&eveningid=1&sectionid=2'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
      }
      Osm::Term.stub(:get_for_section) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>''}) }

      meeting = Osm::Meeting.new(:id=>1, :section_id=>2)
      meeting.delete(@api).should be_true
    end

  end
end
