# encoding: utf-8
require 'spec_helper'

describe "Badge" do

  it "Create" do
    badge = Osm::Badge.new(
      :name => 'name',
      :requirement_notes => 'notes',
      :key => 'key',
      :sections_needed => 1,
      :total_needed => 2,
      :needed_from_section => {'a' => 1},
      :requirements => [],
    )

    badge.name.should == 'name'
    badge.requirement_notes.should == 'notes'
    badge.key.should == 'key'
    badge.sections_needed.should == 1
    badge.total_needed.should == 2
    badge.needed_from_section.should == {'a' => 1}
    badge.requirements.should == []
    badge.valid?.should be_true
  end

  it "Create Requirement" do
    requirement = Osm::Badge::Requirement.new(
      :name => 'name',
      :description => 'description',
      :field => 'field',
      :editable => true,
      :badge_key => 'key',
    )

    requirement.name.should == 'name'
    requirement.description.should == 'description'
    requirement.field.should == 'field'
    requirement.editable.should == true
    requirement.badge_key.should == 'key'
    requirement.valid?.should be_true
  end

  it "Create Data" do
    data = Osm::Badge::Data.new(
      :member_id => 1,
      :completed => true,
      :awarded_date => Date.new(2000, 1, 2),
      :requirements => {},
      :section_id => 2,
      :badge_key => 'key',
    )

    data.member_id.should == 1
    data.completed.should == true
    data.awarded_date.should == Date.new(2000, 1, 2)
    data.requirements.should == {}
    data.section_id.should == 2
    data.badge_key.should == 'key'
    data.valid?.should be_true
  end


  describe "Using the OSM API" do

    describe "Get Badges" do

      before :each do
        @data = {
          "badgeOrder" => "badge",
          "structure" => {
            "badge" => [
              {
                "rows" => [
                  {"name" => "First name","field" => "firstname","width" => "120px"},
                  {"name" => "Last name","field" => "lastname","width" => "120px"},
                  {"name" => "Done","field" => "completed","width" => "70px","formatter" => "doneFormatter"},
                  {"name" => "Awarded","field" => "awardeddate","width" => "100px","formatter" => "dueFormatter"}
                ],
                "numactivities" => "23",
                "noscroll" => true
	      },{
                "rows" => [
                  {"name" => "r_name","field" => "r_field","width" => "80px","formatter" => "cellFormatter","tooltip" => "r_description","editable" => "true"}
		]
              }
            ],
          },
          "details" => {
            "badge" => {
              "shortname" => "badge",
              "name" => "b_name",
              "description" => "b_req_notes",
              "picture" => "badge.png",
              "config" => "{\"sectionsneeded\":\"1\",\"totalneeded\":\"2\",\"sections\":{\"a\":\"1\"}}",
              "order" => "1",
              "groupname" => nil,
              "status" => "3",
              "userid" => "0",
              "table" => "table"
            },
          },
          "stock" => {"sectionid" => "1","badge" => "3"}
        }
        @data = @data.to_json
      end

      it "Core" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=core&sectionid=1&section=beavers&termid=2", :body => @data)
        Osm::Term.stub(:get_current_term_for_section){ Osm::Term.new(:id => 2) }

        badges = Osm::CoreBadge.get_badges_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers))
        badges.size.should == 1
        badge = badges[0]
        badge.name.should == 'b_name'
        badge.requirement_notes.should == 'b_req_notes'
        badge.key.should == 'badge'
        badge.sections_needed.should == 1
        badge.total_needed.should == 2
        badge.needed_from_section.should == {'a' => 1}
        badge.requirements.should == [Osm::Badge::Requirement.new(:name=>'r_name', :description=>'r_description', :field=>'r_field', :editable=>true, :badge_key=>'badge')]
      end

      it "Challenge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=challenge&sectionid=1&section=beavers&termid=2", :body => @data)
        Osm::Term.stub(:get_current_term_for_section){ Osm::Term.new(:id => 2) }

        badges = Osm::ChallengeBadge.get_badges_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers))
        badges.size.should == 1
        badge = badges[0]
        badge.name.should == 'b_name'
        badge.requirement_notes.should == 'b_req_notes'
        badge.key.should == 'badge'
        badge.sections_needed.should == 1
        badge.total_needed.should == 2
        badge.needed_from_section.should == {'a' => 1}
        badge.requirements.should == [Osm::Badge::Requirement.new(:name=>'r_name', :description=>'r_description', :field=>'r_field', :editable=>true, :badge_key=>'badge')]
      end

      it "Staged" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=staged&sectionid=1&section=beavers&termid=2", :body => @data)
        Osm::Term.stub(:get_current_term_for_section){ Osm::Term.new(:id => 2) }

        badges = Osm::StagedBadge.get_badges_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers))
        badges.size.should == 1
        badge = badges[0]
        badge.name.should == 'b_name'
        badge.requirement_notes.should == 'b_req_notes'
        badge.key.should == 'badge'
        badge.sections_needed.should == 1
        badge.total_needed.should == 2
        badge.needed_from_section.should == {'a' => 1}
        badge.requirements.should == [Osm::Badge::Requirement.new(:name=>'r_name', :description=>'r_description', :field=>'r_field', :editable=>true, :badge_key=>'badge')]
      end

      it "Activity" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=activity&sectionid=1&section=beavers&termid=2", :body => @data)
        Osm::Term.stub(:get_current_term_for_section){ Osm::Term.new(:id => 2) }

        badges = Osm::ActivityBadge.get_badges_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers))
        badges.size.should == 1
        badge = badges[0]
        badge.name.should == 'b_name'
        badge.requirement_notes.should == 'b_req_notes'
        badge.key.should == 'badge'
        badge.sections_needed.should == 1
        badge.total_needed.should == 2
        badge.needed_from_section.should == {'a' => 1}
        badge.requirements.should == [Osm::Badge::Requirement.new(:name=>'r_name', :description=>'r_description', :field=>'r_field', :editable=>true, :badge_key=>'badge')]
      end

    end

    describe "Get badge data for a section" do
      
      before :each do
        @data = {
          'identifier' => 'scoutid',
          'items' => [{
            'scoutid' => 3,
            'firstname' => 'fn',
            'lastname' => 'ln',
            'sid' => '',
            'completed' => '1',
            'awarded' => '',
            'awardeddate' => '2000-01-02',
            'patrolid' => 4,
            'a_1' => 'd',
          }]
        }
        @data = @data.to_json
      end

      it "Core badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=core&section=beavers&c=badge&sectionid=1", :body => @data)
        datas = Osm::CoreBadge.get_badge_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 'badge', 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.completed.should == true
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge_key.should == 'badge'
      end

      it "Challenge badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=challenge&section=beavers&c=badge&sectionid=1", :body => @data)
        datas = Osm::ChallengeBadge.get_badge_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 'badge', 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.completed.should == true
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge_key.should == 'badge'
      end

      it "Staged badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=staged&section=beavers&c=badge&sectionid=1", :body => @data)
        datas = Osm::StagedBadge.get_badge_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 'badge', 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.completed.should == true
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge_key.should == 'badge'
      end

      it "Activity badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=activity&section=beavers&c=badge&sectionid=1", :body => @data)
        datas = Osm::ActivityBadge.get_badge_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 'badge', 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.completed.should == true
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge_key.should == 'badge'
      end

    end

  end

end
