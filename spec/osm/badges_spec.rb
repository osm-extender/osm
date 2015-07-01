# encoding: utf-8
require 'spec_helper'

describe "Badges" do


  describe "Using the OSM API" do

    it "Get due badges" do
      data = {
        'includeStock' => true,
        'count' => 2,
        'badgesToBuy' => 0,
        'description' => {
          '93_0' => {
            'badge_identifier' => '93_0',
            'msg' => 'You do not have enough badges!',
            'name' => 'Participation',
            'picture' => '',
            'typeLabel' => 'Staged',
            'type_id' => 3
          },
          '145_0' => {
            'badge_identifier' => '145_0',
            'name' => 'Badge Name',
            'picture' => '',
            'typeLabel' => 'Activity',
            'type_id' => 2
          },
        },
        'pending' => {
          '93_0' => [
            {
              'badge_id' => '93',
              'badge_identifier' => '93_0',
              'badge_version' => '0',
              'completed' => '2',
              'current_stock' => '20',
              'extra' => 'Lvl 2',
              'firstname' => 'John',
              'label' => 'Staged',
              'lastname' => 'Doe',
              'name' => 'Participation',
              'patrolid' => '1502',
              'pic' => true,
              'picture' => '',
              'scout_id' => '1',
              'sid' => '1',
              'type_id' => '3',
            },
            {
              'badge_id' => '93',
              'badge_identifier' => '93_0',
              'badge_version' => '0',
              'completed' => '2',
              'current_stock' => '20',
              'extra' => 'Lvl 2',
              'firstname' => 'Jane',
              'label' => 'Staged',
              'lastname' => 'Doe',
              'name' => 'Participation',
              'patrolid' => '1502',
              'pic' => true,
              'picture' => '',
              'scout_id' => '2',
              'sid' => '2',
              'type_id' => '3',
            },
          ],
          '145_0' => [{
            'badge_id' => '145',
            'badge_identifier' => '145_0',
            'badge_version' => '0',
            'completed' => '1',
            'current_stock' => '10',
            'firstname' => 'John',
            'label' => 'Activity',
            'lastname' => 'Doe',
            'name' => 'Badge Name',
            'patrolid' => '1502',
            'pic' => true,
            'picture' => '',
            'scout_id' => '1',
            'sid' => '1',
            'type_id' => '2',
          }],
        },
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/badges/due/?action=get&section=cubs&sectionid=1&termid=2", :body => data.to_json, :content_type => 'application/json')

      db = Osm::Badges.get_due_badges(@api, Osm::Section.new(:id => 1, :type => :cubs), 2)
      db.empty?.should == false
      db.badge_names.should == {'145_0_1'=>'Activity - Badge Name', '93_0_2'=>'Staged - Participation (Lvl 2)'}
      db.by_member.should == {1=>['93_0_2', '145_0_1'], 2=>['93_0_2']}
      db.member_names.should == {1 => 'John Doe', 2 => 'Jane Doe'}
      db.badge_stock.should == {'93_0_2'=>20, '145_0_1'=>10}
      db.totals.should == {'93_0_2'=>2, '145_0_1'=>1}
      db.valid?.should == true
    end

    it "handles an empty array representing no due badges" do
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/badges/due/?action=get&section=cubs&sectionid=1&termid=2", :body => '[]', :content_type => 'application/json')
      db = Osm::Badges.get_due_badges(@api, Osm::Section.new(:id => 1, :type => :cubs), 2)
      db.should_not be_nil
    end


    it "Fetch badge stock levels" do
      badges_body = {
        'identifier' => 'badge_id_level',
        'items' => [
          { 'shortname' => 'badge_1', 'stock' => 1, 'desired' => 0, 'due' => 0, 'badge_id_level' => '100_1' },
          { 'shortname' => 'badge_2', 'stock' => 2, 'desired' => 0, 'due' => 0, 'badge_id_level' => '200_2' },
        ]
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/badges/stock/?action=getBadgeStock&section=beavers&section_id=1&term_id=2", :body => badges_body.to_json, :content_type => 'application/json')
      Osm::Term.stub(:get_current_term_for_section) { Osm::Term.new(:id => 2) }

      section = Osm::Section.new(:id => 1, :type => :beavers)
      Osm::Badges.get_stock(@api, section).should == {'100_1' => 1, '200_2' => 2}
    end

    describe "Update badge stock levels" do

      it "Succeds" do
        url = "https://www.onlinescoutmanager.co.uk/ext/badges.php?action=updateStock"
        HTTParty.should_receive(:post).with(url, {:body => {
          'apiid' => @CONFIGURATION[:api][:osm][:id],
          'token' => @CONFIGURATION[:api][:osm][:token],
          'userid' => 'user_id',
          'secret' => 'secret',
          'stock' => 10,
          'sectionid' => 2,
          'section' => :beavers,
          'type' => 'current',
          'level' => 1,
          'badge_id' => 3
        }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"ok":true}'}) }

        section = Osm::Section.new(:id => 2, :type => :beavers)
        Osm::Badges.update_stock(@api, section, 3, 10).should == true
      end

      it "Fails" do
        HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"ok":false}'}) }
        section = Osm::Section.new(:id => 1, :type => :beavers)
        Osm::Badges.update_stock(@api, section, 3, 10).should == false
      end

    end

  end

end
