# encoding: utf-8
require 'spec_helper'

describe "Grouping" do

  it "Sorts by section_id then name" do
    g1 = Osm::Grouping.new(:section_id => 1, :name => 'a')
    g2 = Osm::Grouping.new(:section_id => 2, :name => 'a')
    g3 = Osm::Grouping.new(:section_id => 2, :name => 'b')

    data = [g3, g1, g2]
    data.sort.should == [g1, g2, g3]
  end

  describe "Using the API" do

    it "Get for section" do
      data = {'patrols' => [{
        'patrolid' => 1,
        'name' => 'Patrol Name',
        'active' => 1,
        'points' => '3',
      }]}
      $api.should_receive(:post_query).with('users.php?action=getPatrols&sectionid=2').and_return(data)

      patrols = Osm::Grouping.get_for_section(api: $api, section: 2)
      patrols.size.should == 1
      patrol = patrols[0]
      patrol.id.should == 1
      patrol.section_id.should == 2
      patrol.name.should == 'Patrol Name'
      patrol.active.should == true
      patrol.points.should == 3
      patrol.valid?.should == true
    end

    it "Handles no data" do
      $api.should_receive(:post_query).with('users.php?action=getPatrols&sectionid=2').and_return(nil)
      patrols = Osm::Grouping.get_for_section(api: $api, section: 2)
      patrols.size.should == 0
    end


    it "Update in OSM (succeded)" do
      grouping = Osm::Grouping.new(
        id: 1,
        section_id: 2,
        active: true,
        points: 3
      )
      grouping.name = 'Grouping'

      post_data = {
        'patrolid' => grouping.id,
        'name' => grouping.name,
        'active' => grouping.active,
      }
      $api.should_receive(:post_query).with('users.php?action=editPatrol&sectionid=2', post_data: post_data).and_return(nil)

      grouping.update($api).should == true
    end

    it "Update points in OSM (succeded)" do
      grouping = Osm::Grouping.new(
        id: 1,
        section_id: 2,
        active: true,
        name: 'Grouping',
      )
      grouping.points = 3

      post_data = {
        'patrolid' => grouping.id,
        'points' => grouping.points,
      }
      $api.should_receive(:post_query).with('users.php?action=updatePatrolPoints&sectionid=2', post_data: post_data).and_return({})

      grouping.update($api).should == true
    end

    it "Update in OSM (failed)" do
      grouping = Osm::Grouping.new(
        id: 1,
        section_id: 2,
        points: 3,
      )
      grouping.name = 'Grouping'
      grouping.active = true

      $api.should_receive(:post_query).and_return({"done" => false})

      grouping.update($api).should == false
    end

    it "Update points in OSM (failed)" do
      grouping = Osm::Grouping.new(
        id: 1,
        section_id: 2,
        name: 'Name',
        active: true,
      )
      grouping.points = 3

      $api.should_receive(:post_query).and_return({"done" => false})

      grouping.update($api).should == false
    end

  end

end
