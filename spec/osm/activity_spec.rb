# encoding: utf-8
require 'spec_helper'

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
          'activityid' => '1',
          'section' => 'section',
          'badgetype' => 'type',
          'badge' => 'badge',
          'columnname' => 'col_name',
          'label' => 'This is a label',
        }
      ]
    }
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/programme.php?action=getActivity&id=1", :body => body.to_json)


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
    activity.editable.should == true
    activity.deletable.should == false
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
    activity.badges[0].activity_id.should == 1
    activity.badges[0].section_type.should == :section
    activity.badges[0].type.should == :type
    activity.badges[0].badge.should == 'badge'
    activity.badges[0].requirement.should == 'col_name'
    activity.badges[0].label.should == 'This is a label'

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
      'links' => '[{"activityid":"2","section":"beavers","badgetype":"t","badge":"b","columnname":"r","label":"l"}]',
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
      :badges => [Osm::Activity::Badge.new(:activity_id=>2, :section_type=>:beavers, :type=>:t, :badge=>'b', :requirement=>'r', :label=>'l')],
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