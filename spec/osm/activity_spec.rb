# encoding: utf-8
require 'spec_helper'

describe "Activity" do

  it "Get OSM link" do
    activity = Osm::Activity.new(
      id: 1,
      running_time: 10,
      title: 'Title',
      description: 'Description',
      resources: 'Resources',
      instructions: 'Instructions',
      location: :indoors,
    )
    activity.osm_link.should == 'https://www.onlinescoutmanager.co.uk/?l=p1'
  end

  it "Sorts by id then version" do
    Osm::Activity.new.send(:sort_by).should == ['id', 'version']
  end


  describe "Activity::File" do
    it "Sorts by activity_id then name" do
      Osm::Activity::File.new.send(:sort_by).should == ['activity_id', 'name']
    end
  end


  describe "Activity::Version" do
    it "Sorts by activity_id then version" do
      Osm::Activity::Version.new.send(:sort_by).should == ['activity_id', 'version']
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
      $api.should_receive(:post_query).with('programme.php?action=getActivity&id=1').and_return(body)

      activity = Osm::Activity.get(api: $api, id: 1)
  
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
      activity.badges[0].badge_type.should == :activity
      activity.badges[0].badge_section.should == :cubs
      activity.badges[0].badge_name.should == 'Fire Safety'
      activity.badges[0].badge_id.should == 181
      activity.badges[0].badge_version.should == 0
      activity.badges[0].requirement_id.should == 93384
      activity.badges[0].requirement_label.should == 'B: Fire drill'
      activity.badges[0].data.should == 'Yes'
      activity.valid?.should == true
    end
  
  
    it "Add activity to programme (succeded)" do
      post_data = {
        'meetingdate' => '2000-01-02',
        'sectionid' => 1,
        'activityid' => 2,
        'notes' => 'Notes',
      }
      $api.should_receive(:post_query).with('programme.php?action=addActivityToProgramme', post_data: post_data).and_return({'result' => 0})
  
      activity = Osm::Activity.new(id: 2)
      activity.add_to_programme(api: $api, section: 1, date: Date.new(2000, 1, 2), notes: 'Notes').should == true
    end
  
    it "Add activity to programme (failed)" do
      post_data = {
        'meetingdate' => '2000-01-02',
        'sectionid' => 1,
        'activityid' => 2,
        'notes' => 'Notes',
      }
      $api.should_receive(:post_query).with('programme.php?action=addActivityToProgramme', post_data: post_data).and_return({'result' => 1})

      activity = Osm::Activity.new(id: 2)
      activity.add_to_programme(api: $api, section: 1, date: Date.new(2000, 1, 2), notes: 'Notes').should == false
    end
  
  
    it "Update activity in OSM (succeded)" do
      post_data = {
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
  
      $api.should_receive(:post_query).with('programme.php?action=update', post_data: post_data).and_return({'result' => true})
  
      activity = Osm::Activity.new(
        id: 2,
        title: 'title',
        description: 'description',
        resources: 'resources',
        instructions: 'instructions',
        files: [Osm::Activity::File.new(id:3, activity_id:2, file_name:'fn', name:'n'), Osm::Activity::File.new(:id=>4, :activity_id=>2, :file_name=>'fn2', :name=>'n2')],
        running_time: 5,
        location: :indoors,
        sections: [:beavers, :cubs],
        tags: ['tag1', 'tag2'],
        badges: [Osm::Activity::Badge.new(
          badge_type: :activity,
          badge_section: :beavers,
          requirement_label: 'l',
          data: '',
          badge_name: 'Badge name',
          badge_id: 181,
          badge_version: 0,
          requirement_id: 93384,
        )],
        shared: 0,
        section_id: 1,
      )
      activity.update(api: $api, section: 1, secret_update: true).should == true
    end
  
    it "Update activity in OSM (failed)" do
      activity = Osm::Activity.new(
        id: 2,
        title: 'title',
        description: 'description',
        resources: 'resources',
        instructions: 'instructions',
        location: :indoors,
        running_time: 0,
      )
      $api.should_receive(:post_query).and_return({"result" => false})
      activity.update(api: $api, section: 1, secret_update: true).should == false
    end
  
  end

end
