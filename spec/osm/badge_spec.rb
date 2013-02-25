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
              "shortname" => "membership",
              "name" => "b_name",
              "description" => "b_req_notes",
              "picture" => "badge.png",
              "config" => "{\"sectionsneeded\":\"1\",\"totalneeded\":\"2\",\"sections\":{\"a\":\"1\"}}",
              "order" => "1",
              "groupname" => nil,
              "status" => "3",
              "userid" => "0",
              "table" => "badge"
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

  end

end
