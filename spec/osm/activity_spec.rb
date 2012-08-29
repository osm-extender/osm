# encoding: utf-8
require 'spec_helper'

describe "Activity" do

  it "Create from API data" do
    data = {
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
    activity = Osm::Activity.from_api(data)

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
  end

end