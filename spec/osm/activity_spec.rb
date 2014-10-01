# encoding: utf-8
require 'spec_helper'

describe "Activity" do

  it "Get OSM link" do
    activity = Osm::Activity.new(
      :id => 1,
      :running_time => 10,
      :title => 'Title',
      :description => 'Description',
      :resources => 'Resources',
      :instructions => 'Instructions',
      :location => :indoors,
    )
    activity.osm_link.should == 'https://www.onlinescoutmanager.co.uk/?l=p1'
  end

  it "Sorts by id then version" do
    a1 = Osm::Activity.new(:id => 1, :version => 1)
    a2 = Osm::Activity.new(:id => 2, :version => 1)
    a3 = Osm::Activity.new(:id => 2, :version => 2)

    activities = [a2, a3, a1]
    activities.sort.should == [a1, a2, a3]
  end


  describe "Activity::File" do
    it "Sorts by activity_id then name" do
      a1 = Osm::Activity::File.new(:activity_id => 1, :name => 'a')
      a2 = Osm::Activity::File.new(:activity_id => 2, :name => 'a')
      a3 = Osm::Activity::File.new(:activity_id => 2, :name => 'b')

      activities = [a2, a3, a1]
      activities.sort.should == [a1, a2, a3]
    end
  end


  describe "Activity::Version" do
    it "Sorts by activity_id then version" do
      a1 = Osm::Activity::File.new(:activity_id => 1, :version => 1)
      a2 = Osm::Activity::File.new(:activity_id => 2, :version => 1)
      a3 = Osm::Activity::File.new(:activity_id => 2, :version => 2)

      activities = [a2, a3, a1]
      activities.sort.should == [a1, a2, a3]
    end
  end


  describe "Using The API" do
  
    it "Get One" do
      body = {
          'details' => {
          'activityid' => '1',
          'version' => '0',
          'groupid' => '2',
          'userid' => '3',
          'title' => 'Activity Name',
          'description' => 'Description',
          'resources' => 'Resources',
          'instructions' => 'Instructions',
          'runningtime' => '15',
          'location' => 'indoors',
          'shared' => '0',
          'rating' => '4',
          'facebook' => ''
        },
        'editable' => true,
        'deletable' => false,
        'used' => 3,
        'versions' => [
          {
            'value' => '0',
            'userid' => '1',
            'firstname' => 'Alice',
            'label' => 'Current version - Alice',
            'selected' => 'selected'
          }
        ],
        'sections' => ['beavers', 'cubs'],
        'tags' => ['Tag 1', 'Tag2'],
        'files' => [
          {
            'fileid' => '6',
            'activityid' => '1',
            'filename' => 'File Name',
            'name' => 'Name',
          }
        ],
        'badges' => [
          {
            'badge' => 'activity_firesafety',
            'badgeLongName' => 'Fire Safety',
            'badge_id' => '181',
            'badge_version' => '0',
            'badgetype' => 'activity',
            'badgetypeLongName' => 'Activity',
            'column_id' => '93384',
            'columnname' => 'b_01',
            'columnnameLongName' => 'B: Fire drill',
            'data' => 'Yes',
            'section' => 'cubs',
            'sectionLongName' => 'Cubs',
          }
        ]
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/programme.php?action=getActivity&id=1", :body => body.to_json, :content_type => 'application/json')


      activity = Osm::Activity.get(@api, 1)
  
      activity.id.should == 1
      activity.version.should == 0
      activity.group_id.should == 2
      activity.user_id.should == 3
      activity.title.should == 'Activity Name'
      activity.description.should == 'Description'
      activity.resources.should == 'Resources'
      activity.instructions.should == 'Instructions'
      activity.running_time.should == 15
      activity.location.should == :indoors
      activity.shared.should == 0
      activity.rating.should == 4
      activity.editable.should be_true
      activity.deletable.should be_false
      activity.used.should == 3
      activity.versions[0].version.should == 0
      activity.versions[0].created_by.should == 1
      activity.versions[0].created_by_name.should == 'Alice'
      activity.versions[0].label.should == 'Current version - Alice'
      activity.sections.should == [:beavers, :cubs]
      activity.tags.should == ['Tag 1', 'Tag2']
      activity.files[0].id.should == 6
      activity.files[0].activity_id.should == 1
      activity.files[0].file_name.should == 'File Name'
      activity.files[0].name.should == 'Name'
      activity.badges[0].badge_type.should == :activity
      activity.badges[0].badge_section.should == :cubs
      activity.badges[0].badge_name.should == 'Fire Safety'
      activity.badges[0].badge_id.should == 181
      activity.badges[0].badge_version.should == 0
      activity.badges[0].requirement_id.should == 93384
      activity.badges[0].requirement_label.should == 'B: Fire drill'
      activity.badges[0].data.should == 'Yes'
      activity.valid?.should be_true
    end
  
  
    it "Add activity to programme (succeded)" do
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
  
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":0}'}) }
      activity = Osm::Activity.new(:id => 2)
      activity.add_to_programme(@api, 1, Date.new(2000, 1, 2), 'Notes').should be_true
    end
  
    it "Add activity to programme (failed)" do
      HTTParty.should_receive(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":1}'}) }
      activity = Osm::Activity.new(:id => 2)
      activity.add_to_programme(@api, 1, Date.new(2000, 1, 2), 'Notes').should be_false
    end
  
  
    it "Update activity in OSM (succeded)" do
      url = 'https://www.onlinescoutmanager.co.uk/programme.php?action=update'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'title' => 'title',
        'description' => 'description',
        'resources' => 'resources',
        'instructions' => 'instructions',
        'id' => 2,
        'files' => '3,4',
        'time' => '5',
        'location' => :indoors,
        'sections' => '["beavers","cubs"]',
        'tags' => '["tag1","tag2"]',
        'links' => '[{"badge_id":"181","badge_version":"0","column_id":"93384","badge":null,"badgeLongName":"Badge name","columnname":null,"columnnameLongName":"l","data":"","section":"beavers","sectionLongName":null,"sections":["beavers","cubs"],"badgetype":"activity","badgetypeLongName":null}]',
        'shared' => 0,
        'sectionid' => 1,
        'secretEdit' => true,
      }
  
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":true}'}) }
      activity = Osm::Activity.new(
        :id => 2,
        :title => 'title',
        :description => 'description',
        :resources => 'resources',
        :instructions => 'instructions',
        :files => [Osm::Activity::File.new(:id=>3, :activity_id=>2, :file_name=>'fn', :name=>'n'), Osm::Activity::File.new(:id=>4, :activity_id=>2, :file_name=>'fn2', :name=>'n2')],
        :running_time => 5,
        :location => :indoors,
        :sections => [:beavers, :cubs],
        :tags => ['tag1', 'tag2'],
        :badges => [Osm::Activity::Badge.new(
          :badge_type => :activity,
          :badge_section => :beavers,
          :requirement_label => 'l',
          :data => '',
          :badge_name => 'Badge name',
          :badge_id => 181,
          :badge_version => 0,
          :requirement_id => 93384,
        )],
        :shared => 0,
        :section_id => 1,
      )
      activity.update(@api, 1, true).should be_true
    end
  
    it "Update activity in OSM (failed)" do
      HTTParty.should_receive(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"result":false}'}) }
      activity = Osm::Activity.new(
        :id => 2,
        :title => 'title',
        :description => 'description',
        :resources => 'resources',
        :instructions => 'instructions',
        :location => :indoors,
        :running_time => 0,
      )
      activity.update(@api, 1, true).should be_false
    end
  
  end

end
