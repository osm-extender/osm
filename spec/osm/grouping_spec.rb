# encoding: utf-8
require 'spec_helper'

describe "Grouping" do

  describe "Using the API" do

    it "Get for section" do
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


    it "Update in OSM (succeded)" do
      grouping = Osm::Grouping.new(
        :id => 1,
        :section_id => 2,
        :active => true,
        :points => 3
      )
      grouping.name = 'Grouping'

      url = "https://www.onlinescoutmanager.co.uk/users.php?action=editPatrol&sectionid=#{grouping.section_id}"
      HTTParty.should_receive(:post).with(url, {:body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'patrolid' => grouping.id,
        'name' => grouping.name,
        'active' => grouping.active,
      }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>''}) }

      grouping.update(@api).should be_true
    end

    it "Update points in OSM (succeded)" do
      grouping = Osm::Grouping.new(
        :id => 1,
        :section_id => 2,
        :active => true,
        :name => 'Grouping'
      )
      grouping.points = 3

      url = "https://www.onlinescoutmanager.co.uk/users.php?action=updatePatrolPoints&sectionid=#{grouping.section_id}"
      HTTParty.should_receive(:post).with(url, {:body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'patrolid' => grouping.id,
        'points' => grouping.points,
      }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{}'}) }

      grouping.update(@api).should be_true
    end
    it "Update in OSM (failed)" do
      grouping = Osm::Grouping.new(
        :id => 1,
        :section_id => 2,
      )
      grouping.name = 'Grouping'
      grouping.points = 3
      grouping.active = true

      HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"done":false}'}) }
      grouping.update(@api).should be_false
    end

  end

end