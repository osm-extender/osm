# encoding: utf-8
require 'spec_helper'

describe "Grouping" do

  describe "Using the API" do

    it "Create" do
      body = {'patrols' => [{
        'patrolid' => 1,
        'name' => 'Patrol Name',
        'active' => 1,
        'points' => '3',
      }]}
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=getPatrols&sectionid=2", :body => body.to_json)

      patrols = Osm::Grouping.get_for_section(@api, 2)
      patrols.size.should == 1
      patrol = patrols[0]
      patrol.id.should == 1
      patrol.section_id.should == 2
      patrol.name.should == 'Patrol Name'
      patrol.active.should == true
      patrol.points.should == 3
      patrol.valid?.should be_true
    end

    it "Handles no data" do
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=getPatrols&sectionid=2", :body => '')
      patrols = Osm::Grouping.get_for_section(@api, 2)
      patrols.size.should == 0
    end

  end

end