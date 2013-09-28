# encoding: utf-8
require 'spec_helper'

describe "Badge" do

  it "Create" do
    badge = Osm::Badge.new(
      :name => 'name',
      :requirement_notes => 'notes',
      :osm_key => 'key',
      :sections_needed => 1,
      :total_needed => 2,
      :needed_from_section => {'a' => 1},
      :requirements => [],
    )

    badge.name.should == 'name'
    badge.requirement_notes.should == 'notes'
    badge.osm_key.should == 'key'
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
      :badge => Osm::Badge.new(:osm_key => 'key'),
    )

    requirement.name.should == 'name'
    requirement.description.should == 'description'
    requirement.field.should == 'field'
    requirement.editable.should == true
    requirement.badge.osm_key.should == 'key'
    requirement.valid?.should be_true
  end

  it "Create Data" do
    data = Osm::Badge::Data.new(
      :member_id => 1,
      :first_name => 'First',
      :last_name => 'Last',
      :completed => 4,
      :awarded => 3,
      :awarded_date => Date.new(2000, 1, 2),
      :requirements => {},
      :section_id => 2,
      :badge => Osm::Badge.new(:osm_key => 'key'),
    )

    data.member_id.should == 1
    data.first_name.should == 'First'
    data.last_name.should == 'Last'
    data.completed.should == 4
    data.awarded.should == 3
    data.awarded_date.should == Date.new(2000, 1, 2)
    data.requirements.should == {}
    data.section_id.should == 2
    data.badge.osm_key.should == 'key'
    data.valid?.should be_true
  end


  it "Compare badges by name then osm_key" do
    b1 = Osm::Badge.new(:name => 'A', :osm_key => 'a')
    b2 = Osm::Badge.new(:name => 'B', :osm_key => 'a')
    b3 = Osm::Badge.new(:name => 'B', :osm_key => 'b')
    badges = [b3, b1, b2]
    badges.sort.should == [b1, b2, b3]
  end

  it "Compare badge requirements by badge then field" do
    b1 = Osm::Badge::Requirement.new(:badge => Osm::Badge.new(:name => 'A'), :field => 'a')
    b2 = Osm::Badge::Requirement.new(:badge => Osm::Badge.new(:name => 'B'), :field => 'a')
    b3 = Osm::Badge::Requirement.new(:badge => Osm::Badge.new(:name => 'B'), :field => 'b')
    badges = [b3, b1, b2]
    badges.sort.should == [b1, b2, b3]
  end

  it "Compare badge data by badge, section_id then member_id" do
    b1 = Osm::Badge::Data.new(:badge => Osm::Badge.new(:name => 'A'), :section_id => 1, :member_id => 1)
    b2 = Osm::Badge::Data.new(:badge => Osm::Badge.new(:name => 'B'), :section_id => 1, :member_id => 1)
    b3 = Osm::Badge::Data.new(:badge => Osm::Badge.new(:name => 'B'), :section_id => 2, :member_id => 1)
    b4 = Osm::Badge::Data.new(:badge => Osm::Badge.new(:name => 'B'), :section_id => 2, :member_id => 2)
    badges = [b3, b4, b1, b2]
    badges.sort.should == [b1, b2, b3, b4]
  end


  it "Get total requirements gained for a member" do
    data = Osm::Badge::Data.new(
      :requirements => {
        'a_1' => 'a',
        'a_2' => 'yes',
        'a_3' => '2000-01-02',
        'a_4' => 1,
        'b_1' => 'x',
        'b_2' => 'xYES',
        'b_3' => '',
        'b_4' => nil,
        'b_5' => 0,
      }
    )
    data.total_gained.should == 4
  end

  it "Get total requirements met in each section for a member" do
    badge = Osm::Badge.new(
      :needed_from_section => {'a' => 1, 'b' => 2},
      :requirements => [
        Osm::Badge::Requirement.new(:field => 'a_1'),
        Osm::Badge::Requirement.new(:field => 'a_2'),
        Osm::Badge::Requirement.new(:field => 'b_1'),
        Osm::Badge::Requirement.new(:field => 'b_2'),
        Osm::Badge::Requirement.new(:field => 'y_1'),
        Osm::Badge::Requirement.new(:field => 'y_2'),
      ]
    )
    data = Osm::Badge::Data.new(
      :badge => badge,
      :requirements => {
        'a_1' => 'x',
        'a_2' => '',
        'b_1' => 'yes',
        'b_2' => '2000-01-02',
        'y_1' => 1,
      }
    )
    data.gained_in_sections.should == {'a' => 0, 'b' => 2, 'y' => 1}
  end

  it "Get number of sections met for a member" do
    badge = Osm::Badge.new(
      :needed_from_section => {'a' => 1, 'b' => 2, 'c' => 1},
      :requirements => [
        Osm::Badge::Requirement.new(:field => 'a_1'),
        Osm::Badge::Requirement.new(:field => 'a_2'),
        Osm::Badge::Requirement.new(:field => 'b_1'),
        Osm::Badge::Requirement.new(:field => 'b_2'),
        Osm::Badge::Requirement.new(:field => 'c_1'),
      ]
    )
    data = Osm::Badge::Data.new(
      :badge => badge,
      :requirements => {'a_1' => 'x', 'a_2' => '', 'b_1' => 'yes', 'b_2' => '2000-01-02', 'c_1' => 'yes'}
    )
    data.sections_gained.should == 2
  end

  describe "Works out if the badge has been earnt" do
    it "Staged" do
      badge = Osm::StagedBadge.new(:osm_key => 'not_hikes_or_nights')
      data = Osm::Badge::Data.new(:awarded => 2, :badge => badge)

      data.stub(:earnt) { 1 }
      data.earnt?.should be_false

      data.stub(:earnt) { 2 }
      data.earnt?.should be_false

      data.stub(:earnt) { 3 }
      data.earnt?.should be_true
    end

    it "Non staged" do
      badge = Osm::ActivityBadge.new()
      data = Osm::Badge::Data.new(:completed => 1, :awarded => 1, :badge => badge)
      data.earnt?.should be_false

      badge = Osm::ActivityBadge.new()
      data = Osm::Badge::Data.new(:completed => 1, :awarded => 0, :badge => badge)
      data.earnt?.should be_true


      badge = Osm::ActivityBadge.new(:total_needed => 0, :sections_needed => 2, :needed_from_section => {'a' => 2, 'b' => 1})
      data = Osm::Badge::Data.new(:requirements => {'a_01'=>'y', 'a_02'=>'y', 'b_01' => 'y'}, :completed => 0, :awarded => 0, :badge => badge)
      data.earnt?.should be_true

      badge = Osm::ActivityBadge.new(:total_needed => 0, :sections_needed => 2, :needed_from_section => {'a' => 2, 'b' => 1})
      data = Osm::Badge::Data.new(:requirements => {'a_01'=>'y', 'a_02'=>'y', 'b_01' => 'x'}, :completed => 0, :awarded => 0, :badge => badge)
      data.earnt?.should be_false

      badge = Osm::ActivityBadge.new(:total_needed => 3, :sections_needed => 0, :needed_from_section => {'a' => 2, 'b' => 1})
      data = Osm::Badge::Data.new(:requirements => {'a_01'=>'y', 'a_02'=>'y', 'b_01' => 'y'}, :completed => 0, :awarded => 0, :badge => badge)
      data.earnt?.should be_true

      badge = Osm::ActivityBadge.new(:total_needed => 3, :sections_needed => 0, :needed_from_section => {'a' => 2, 'b' => 1})
      data = Osm::Badge::Data.new(:requirements => {'a_01'=>'y', 'a_02'=>'x', 'b_01' => 'y'}, :completed => 0, :awarded => 0, :badge => badge)
      data.earnt?.should be_false

      badge = Osm::ActivityBadge.new(:total_needed => 3, :sections_needed => 2, :needed_from_section => {'a' => 2, 'b' => 1})
      data = Osm::Badge::Data.new(:requirements => {'a_01'=>'y', 'a_02'=>'y', 'b_01' => 'y'}, :completed => 0, :awarded => 0, :badge => badge)
      data.earnt?.should be_true

      badge = Osm::ActivityBadge.new(:total_needed => 1, :sections_needed => 1, :needed_from_section => {'a' => 2, 'b' => 1})
      data = Osm::Badge::Data.new(:requirements => {'a_01'=>'y', 'a_02'=>'y', 'b_01' => 'y'}, :completed => 0, :awarded => 0, :badge => badge)
      data.earnt?.should be_true

      badge = Osm::ActivityBadge.new(:total_needed => 0, :sections_needed => -1, :needed_from_section => {'a' => 2, 'b' => 1})
      data = Osm::Badge::Data.new(:requirements => {'a_01'=>'y', 'a_02'=>'y', 'b_01' => 'y'}, :completed => 0, :awarded => 0, :badge => badge)
      data.earnt?.should be_true

      badge = Osm::ActivityBadge.new(:total_needed => 0, :sections_needed => -1, :needed_from_section => {'a' => 2, 'b' => 1})
      data = Osm::Badge::Data.new(:requirements => {'a_01'=>'y', 'a_02'=>'x', 'b_01' => 'y'}, :completed => 0, :awarded => 0, :badge => badge)
      data.earnt?.should be_false
    end
  end

  describe "Works out what level of a badge has been earnt" do
    it "Staged" do
      badge = Osm::StagedBadge.new(:osm_key => 'not_hikes_or_nights', :needed_from_section => {'a'=>1,'b'=>1,'c'=>1,'d'=>2,'e'=>2})

      data = Osm::Badge::Data.new(:requirements=>{'a_01'=>'','b_01'=>'','c_01'=>'','d_01'=>'','d_02'=>'','e_01'=>'','e_02'=>''}, :badge=>badge)
      data.earnt.should == 0

      data = Osm::Badge::Data.new(:requirements=>{'a_01'=>'y','b_01'=>'','c_01'=>'','d_01'=>'','d_02'=>'','e_01'=>'','e_02'=>''}, :badge=>badge)
      data.earnt.should == 1

      data = Osm::Badge::Data.new(:requirements=>{'a_01'=>'y','b_01'=>'y','c_01'=>'','d_01'=>'y','d_02'=>'','e_01'=>'','e_02'=>''}, :badge=>badge)
      data.earnt.should == 2

      data = Osm::Badge::Data.new(:requirements=>{'a_01'=>'y','b_01'=>'y','c_01'=>'','d_01'=>'y','d_02'=>'y','e_01'=>'','e_02'=>''}, :badge=>badge)
      data.earnt.should == 4
    end

    it "Nights away" do
      badge = Osm::StagedBadge.new(:osm_key => 'nightsaway')

      Osm::Badge::Data.new(:requirements => {'y_01'=>3}, :badge => badge).earnt.should == 1
      Osm::Badge::Data.new(:requirements => {'y_01'=>5}, :badge => badge).earnt.should == 5
      Osm::Badge::Data.new(:requirements => {'y_01'=>6}, :badge => badge).earnt.should == 5
      Osm::Badge::Data.new(:requirements => {'y_01'=>199}, :badge => badge).earnt.should == 175
      Osm::Badge::Data.new(:requirements => {'y_01'=>200}, :badge => badge).earnt.should == 200
      Osm::Badge::Data.new(:requirements => {'y_01'=>999}, :badge => badge).earnt.should == 200
    end

    it "Hikes away" do
      badge = Osm::StagedBadge.new(:osm_key => 'hikes')

      Osm::Badge::Data.new(:requirements => {'y_01'=>3}, :badge => badge).earnt.should == 1
      Osm::Badge::Data.new(:requirements => {'y_01'=>5}, :badge => badge).earnt.should == 5
      Osm::Badge::Data.new(:requirements => {'y_01'=>6}, :badge => badge).earnt.should == 5
      Osm::Badge::Data.new(:requirements => {'y_01'=>49}, :badge => badge).earnt.should == 35
      Osm::Badge::Data.new(:requirements => {'y_01'=>50}, :badge => badge).earnt.should == 50
      Osm::Badge::Data.new(:requirements => {'y_01'=>999}, :badge => badge).earnt.should == 50
    end

    it "Non staged" do
      data = Osm::Badge::Data.new(:badge => Osm::ActivityBadge.new)

      data.stub(:earnt?) { true }
      data.earnt.should == 1

      data.stub(:earnt?) { false }
      data.earnt.should == 0
    end
  end

  it "Works out if the badge has been started" do
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {'a_01' => 'Yes', 'a_02' => ''}).started?.should be_true
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {'a_01' => 'Yes', 'a_02' => ''}, :completed => 1).started?.should be_false
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {'a_01' => 'xNo', 'a_02' => ''}).started?.should be_false
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {'a_01' => '', 'a_02' => ''}).started?.should be_false

    # Staged Badge
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new,
      :requirements => {'a_01' => 'Yes', 'b_01' => 'Yes', 'b_02' => ''},
      :completed => 1,
    ).started?.should be_true
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new(:osm_key => 'nightsaway'),
      :requirements => {'a_01' => 5, 'y_01' => '5', 'custom_26695' => ''},
      :completed => 5,
    ).started?.should be_false
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new(:osm_key => 'hikes'),
      :requirements => {'a_01' => 2, 'y_01' => '2', 'custom_26695' => ''},
      :completed => 1,
    ).started?.should be_true

    # Scout's adventure challenge
    Osm::Badge::Data.new(
      :badge => Osm::ChallengeBadge.new(:osm_key => 'adventure'),
      :requirements => {'y_01' => 5, 'custom_26695' => 'Text'},
      :completed => 0,
    ).started?.should be_true
    Osm::Badge::Data.new(
      :badge => Osm::ChallengeBadge.new(:osm_key => 'adventure'),
      :requirements => {'y_01' => '', 'custom_26695' => ''},
      :completed => 0,
    ).started?.should be_false

    # Scout's community challenge
    Osm::Badge::Data.new(
      :badge => Osm::ChallengeBadge.new(:osm_key => 'community'),
      :requirements => {'y_01' => 5, 'a_01' => '', 'custom_26695' => 'Text'},
      :completed => 0,
    ).started?.should be_true
    Osm::Badge::Data.new(
      :badge => Osm::ChallengeBadge.new(:osm_key => 'community'),
      :requirements => {'y_01' => '', 'a_01' => '4', 'custom_26695' => 'Text'},
      :completed => 0,
    ).started?.should be_true
    Osm::Badge::Data.new(
      :badge => Osm::ChallengeBadge.new(:osm_key => 'community'),
      :requirements => {'y_01' => '', 'a_01' => '', 'custom_26695' => ''},
      :completed => 0,
    ).started?.should be_false

    # Beaver's adventure activity
    Osm::Badge::Data.new(
      :badge => Osm::ActivityBadge.new(:osm_key => 'adventure'),
      :requirements => {'y_01' => 5, 'custom_26695' => 'Text'},
      :completed => 0,
    ).started?.should be_true
    Osm::Badge::Data.new(
      :badge => Osm::ActivityBadge.new(:osm_key => 'adventure'),
      :requirements => {'y_01' => '', 'custom_26695' => ''},
      :completed => 0,
    ).started?.should be_false
  end

  it "Works out what stage of the badge has been started" do
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {'a_01' => 'Yes', 'a_02' => ''}).started.should == 1
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {'a_01' => 'Yes', 'a_02' => ''}, :completed => 1).started.should == 0
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {'a_01' => 'xNo', 'a_02' => ''}).started.should == 0
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {'a_01' => '', 'a_02' => ''}).started.should == 0

    # Staged Badge
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new(:osm_key => 'test'),
      :requirements => {'a_01' => 'Yes', 'b_01' => 'Yes', 'b_02' => ''},
      :completed => 1,
    ).started.should == 2
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new(:osm_key => 'test'),
      :requirements => {'a_01' => 'Yes', 'b_01' => 'Yes', 'b_02' => '', 'c_01' => 'Yes', 'c_02' => ''},
      :completed => 1,
    ).started.should == 2
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new(:osm_key => 'test'),
      :requirements => {'a_01' => '', 'b_01' => '', 'c_01' => '', 'd_01' => '', 'e_01' => ''},
      :completed => 5,
    ).started.should == 0 # No more stages to do
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new(:osm_key => 'nightsaway'),
      :requirements => {'a_01' => 7, 'y_01' => '7', 'custom_26695' => ''},
      :completed => 5,
    ).started.should == 10
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new(:osm_key => 'hikes'),
      :requirements => {'a_01' => 2, 'y_01' => '2', 'custom_26695' => ''},
      :completed => 1,
    ).started.should == 5
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
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=core&sectionid=1&section=beavers&termid=2", :body => @data, :content_type => 'application/json')
        Osm::Term.stub(:get_current_term_for_section){ Osm::Term.new(:id => 2) }

        badges = Osm::CoreBadge.get_badges_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers))
        badges.size.should == 1
        badge = badges[0]
        badge.name.should == 'b_name'
        badge.requirement_notes.should == 'b_req_notes'
        badge.osm_key.should == 'badge'
        badge.sections_needed.should == 1
        badge.total_needed.should == 2
        badge.needed_from_section.should == {'a' => 1}
        badge.requirements.size.should == 1
        requirement = badge.requirements[0]
        requirement.name.should == 'r_name'
        requirement.description.should == 'r_description'
        requirement.field.should == 'r_field'
        requirement.editable.should == true
        requirement.badge.osm_key.should == 'badge'
      end

      it "Challenge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=challenge&sectionid=1&section=beavers&termid=2", :body => @data, :content_type => 'application/json')
        Osm::Term.stub(:get_current_term_for_section){ Osm::Term.new(:id => 2) }

        badges = Osm::ChallengeBadge.get_badges_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers))
        badges.size.should == 1
        badge = badges[0]
        badge.name.should == 'b_name'
        badge.requirement_notes.should == 'b_req_notes'
        badge.osm_key.should == 'badge'
        badge.sections_needed.should == 1
        badge.total_needed.should == 2
        badge.needed_from_section.should == {'a' => 1}
        badge.requirements.size.should == 1
        requirement = badge.requirements[0]
        requirement.name.should == 'r_name'
        requirement.description.should == 'r_description'
        requirement.field.should == 'r_field'
        requirement.editable.should == true
        requirement.badge.osm_key.should == 'badge'
      end

      it "Staged" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=staged&sectionid=1&section=beavers&termid=2", :body => @data, :content_type => 'application/json')
        Osm::Term.stub(:get_current_term_for_section){ Osm::Term.new(:id => 2) }

        badges = Osm::StagedBadge.get_badges_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers))
        badges.size.should == 1
        badge = badges[0]
        badge.name.should == 'b_name'
        badge.requirement_notes.should == 'b_req_notes'
        badge.osm_key.should == 'badge'
        badge.sections_needed.should == 1
        badge.total_needed.should == 2
        badge.needed_from_section.should == {'a' => 1}
        badge.requirements.size.should == 1
        requirement = badge.requirements[0]
        requirement.name.should == 'r_name'
        requirement.description.should == 'r_description'
        requirement.field.should == 'r_field'
        requirement.editable.should == true
        requirement.badge.osm_key.should == 'badge'
      end

      it "Activity" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=activity&sectionid=1&section=beavers&termid=2", :body => @data, :content_type => 'application/json')
        Osm::Term.stub(:get_current_term_for_section){ Osm::Term.new(:id => 2) }

        badges = Osm::ActivityBadge.get_badges_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers))
        badges.size.should == 1
        badge = badges[0]
        badge.name.should == 'b_name'
        badge.requirement_notes.should == 'b_req_notes'
        badge.osm_key.should == 'badge'
        badge.sections_needed.should == 1
        badge.total_needed.should == 2
        badge.needed_from_section.should == {'a' => 1}
        badge.requirements.size.should == 1
        requirement = badge.requirements[0]
        requirement.name.should == 'r_name'
        requirement.description.should == 'r_description'
        requirement.field.should == 'r_field'
        requirement.editable.should == true
        requirement.badge.osm_key.should == 'badge'
      end

      it "For a different section type" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=activity&sectionid=1&section=cubs&termid=2", :body => @data, :content_type => 'application/json')
        Osm::Term.stub(:get_current_term_for_section){ Osm::Term.new(:id => 2) }

        badges = Osm::ActivityBadge.get_badges_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), :cubs)
        badges.size.should == 1
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
            'completed' => '2',
            'awarded' => '1',
            'awardeddate' => '2000-01-02',
            'patrolid' => 4,
            'a_1' => 'd',
          }]
        }
        @data = @data.to_json
      end

      it "Core badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=core&section=beavers&c=badge&sectionid=1", :body => @data, :content_type => 'application/json')
        datas = Osm::CoreBadge.new(:osm_key => 'badge').get_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.first_name.should == 'fn'
        data.last_name.should == 'ln'
        data.completed.should == 2
        data.awarded.should == 1
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge.osm_key.should == 'badge'
      end

      it "Challenge badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=challenge&section=beavers&c=badge&sectionid=1", :body => @data, :content_type => 'application/json')
        datas = Osm::ChallengeBadge.new(:osm_key => 'badge').get_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.first_name.should == 'fn'
        data.last_name.should == 'ln'
        data.completed.should == 2
        data.awarded.should == 1
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge.osm_key.should == 'badge'
      end

      it "Staged badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=staged&section=beavers&c=badge&sectionid=1", :body => @data, :content_type => 'application/json')
        datas = Osm::StagedBadge.new(:osm_key => 'badge').get_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.first_name.should == 'fn'
        data.last_name.should == 'ln'
        data.completed.should == 2
        data.awarded.should == 1
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge.osm_key.should == 'badge'
      end

      it "Activity badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=activity&section=beavers&c=badge&sectionid=1", :body => @data, :content_type => 'application/json')
        datas = Osm::ActivityBadge.new(:osm_key => 'badge').get_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.first_name.should == 'fn'
        data.last_name.should == 'ln'
        data.completed.should == 2
        data.awarded.should == 1
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge.osm_key.should == 'badge'
      end

    end

    describe "Update badge data for a section/member" do

      before :each do
        @update_post_data = {
          'apiid' => @CONFIGURATION[:api][:osm][:id],
          'token' => @CONFIGURATION[:api][:osm][:token],
          'userid' => 'user_id',
          'secret' => 'secret',
          'action' => 'updatesingle',
          'id' => 1,
          'col' => 'a',
          'value' => '2',
          'chal' => 'badge',
          'sectionid' => 2,
        }
        @update_body_data = {'sid' => '1', 'a' => '2', 'b' => '2'}

        @awarded_post_data = {
          'apiid' => @CONFIGURATION[:api][:osm][:id],
          'token' => @CONFIGURATION[:api][:osm][:token],
          'userid' => 'user_id',
          'secret' => 'secret',
          'dateAwarded' => '2000-01-02',
          'sectionid' => 2,
          'section' => :beavers,
          'chal' => 'badge',
          'stagedLevel' => 1,
          'due' => :awarded,
        }
        @awarded_body_data = [{'sid'=>'1', 'awarded'=>'1', 'awardeddate'=>'2000-01-02'}]
        @awarded_url = "https://www.onlinescoutmanager.co.uk/challenges.php?action=award"
      end

      it "Core badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
          :first_name => 'fn',
          :last_name => 'ln',
          :section_id => 2,
          :requirements => {'a' => '1', 'b' => '2'},
          :badge => Osm::CoreBadge.new(
            :osm_key => 'badge',
            :requirements => [
              Osm::Badge::Requirement.new(:field => 'a', :editable => true),
              Osm::Badge::Requirement.new(:field => 'b', :editable => true),
            ]),
          :completed => 0,
        )

        update_url = "https://www.onlinescoutmanager.co.uk/challenges.php?type=core&section=beavers"
        HTTParty.should_receive(:post).with(update_url, {:body => @update_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@update_body_data.to_json}) }
        HTTParty.should_receive(:post).with(@awarded_url, {:body => @awarded_post_data.merge({'type' => :core})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@awarded_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.requirements['a'] = '2'
        data.awarded = 1
        data.awarded_date = Date.new(2000, 1, 2)
        data.update(@api).should be_true
      end

      it "Challenge badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
          :first_name => 'fn',
          :last_name => 'ln',
          :section_id => 2,
          :requirements => {'a' => '1', 'b' => '2'},
          :badge => Osm::ChallengeBadge.new(
            :osm_key => 'badge',
            :requirements => [
              Osm::Badge::Requirement.new(:field => 'a', :editable => true),
              Osm::Badge::Requirement.new(:field => 'b', :editable => true),
            ]),
          :completed => 0,
        )

        update_url = "https://www.onlinescoutmanager.co.uk/challenges.php?type=challenge&section=beavers"
        HTTParty.should_receive(:post).with(update_url, {:body => @update_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@update_body_data.to_json}) }
        HTTParty.should_receive(:post).with(@awarded_url, {:body => @awarded_post_data.merge({'type' => :challenge})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@awarded_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.requirements['a'] = '2'
        data.awarded = 1
        data.awarded_date = Date.new(2000, 1, 2)
        data.update(@api).should be_true
      end

      it "Staged badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
          :first_name => 'fn',
          :last_name => 'ln',
          :section_id => 2,
          :requirements => {'a' => '1', 'b' => '2'},
          :badge => Osm::StagedBadge.new(
            :osm_key => 'badge',
            :requirements => [
              Osm::Badge::Requirement.new(:field => 'a', :editable => true),
              Osm::Badge::Requirement.new(:field => 'b', :editable => true),
            ]),
          :completed => 0,
        )

        update_url = "https://www.onlinescoutmanager.co.uk/challenges.php?type=staged&section=beavers"
        HTTParty.should_receive(:post).with(update_url, {:body => @update_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@update_body_data.to_json}) }
        HTTParty.should_receive(:post).with(@awarded_url, {:body => @awarded_post_data.merge({'type' => :staged})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@awarded_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.requirements['a'] = '2'
        data.awarded = 1
        data.awarded_date = Date.new(2000, 1, 2)
        data.update(@api).should be_true
      end

      it "Activity badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
          :first_name => 'fn',
          :last_name => 'ln',
          :section_id => 2,
          :requirements => {'a' => '1', 'b' => '2'},
          :badge => Osm::ActivityBadge.new(
            :osm_key => 'badge',
            :requirements => [
              Osm::Badge::Requirement.new(:field => 'a', :editable => true),
              Osm::Badge::Requirement.new(:field => 'b', :editable => true),
            ]),
          :completed => 0,
        )

        update_url = "https://www.onlinescoutmanager.co.uk/challenges.php?type=activity&section=beavers"
        HTTParty.should_receive(:post).with(update_url, {:body => @update_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@update_body_data.to_json}) }
        HTTParty.should_receive(:post).with(@awarded_url, {:body => @awarded_post_data.merge({'type' => :activity})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@awarded_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.requirements['a'] = '2'
        data.awarded = 1
        data.awarded_date = Date.new(2000, 1, 2)
        data.update(@api).should be_true
      end

    end


    describe "Mark badge awarded" do

      before :each do
        @awarded_post_data = {
          'apiid' => @CONFIGURATION[:api][:osm][:id],
          'token' => @CONFIGURATION[:api][:osm][:token],
          'userid' => 'user_id',
          'secret' => 'secret',
          'dateAwarded' => '2000-01-02',
          'sectionid' => 2,
          'section' => :beavers,
          'chal' => 'badge',
          'stagedLevel' => 1,
          'due' => :awarded,
        }
        @awarded_body_data = [{'sid'=>'1', 'awarded'=>'1', 'awardeddate'=>'2000-01-02'}]
        @awarded_url = "https://www.onlinescoutmanager.co.uk/challenges.php?action=award"
      end

      it "Core badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
          :section_id => 2,
          :badge => Osm::CoreBadge.new(
            :osm_key => 'badge',
          )
        )

        HTTParty.should_receive(:post).with(@awarded_url, {:body => @awarded_post_data.merge({'type' => :core})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@awarded_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.mark_awarded(@api, Date.new(2000, 1, 2), 1).should be_true
      end

      it "Challenge badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
          :section_id => 2,
          :badge => Osm::ChallengeBadge.new(
            :osm_key => 'badge',
          )
        )

        HTTParty.should_receive(:post).with(@awarded_url, {:body => @awarded_post_data.merge({'type' => :challenge})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@awarded_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.mark_awarded(@api, Date.new(2000, 1, 2), 1).should be_true
      end

      it "Staged badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
          :section_id => 2,
          :badge => Osm::StagedBadge.new(
            :osm_key => 'badge',
          )
        )

        @awarded_body_data[0].merge!({'awarded' => '4'})
        HTTParty.should_receive(:post).with(@awarded_url, {:body => @awarded_post_data.merge({'type' => :staged, 'stagedLevel' => 4})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@awarded_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.mark_awarded(@api, Date.new(2000, 1, 2), 4).should be_true
      end

      it "Activity badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
          :section_id => 2,
          :badge => Osm::ActivityBadge.new(
            :osm_key => 'badge',
          )
        )

        HTTParty.should_receive(:post).with(@awarded_url, {:body => @awarded_post_data.merge({'type' => :activity})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@awarded_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.mark_awarded(@api, Date.new(2000, 1, 2), 1).should be_true
      end

    end


    describe "Get summary data for a section" do

      before :each do
        @data = {
          'items' => [
            {
              'firstname' => 'First',
              'lastname' => 'Last',
              'badge_none' => '',
              'badge_earnt' => '2000-01-02',
            }
          ]
        }
        @data = @data.to_json
      end

      it "Core badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=summary&section=beavers&sectionid=1&termid=2&type=core", :body => @data, :content_type => 'application/json')
        summary = Osm::CoreBadge.get_summary_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        summary.size.should == 1
        summary[0].should == {
          :first_name => 'First',
          :last_name => 'Last',
          'badge_none' => '',
          'badge_earnt' => '2000-01-02',
        }
      end

      it "Challenge badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=summary&section=beavers&sectionid=1&termid=2&type=challenge", :body => @data, :content_type => 'application/json')
        summary = Osm::ChallengeBadge.get_summary_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        summary.size.should == 1
        summary[0].should == {
          :first_name => 'First',
          :last_name => 'Last',
          'badge_none' => '',
          'badge_earnt' => '2000-01-02',
        }
      end

      it "Staged badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=summary&section=beavers&sectionid=1&termid=2&type=staged", :body => @data, :content_type => 'application/json')
        summary = Osm::StagedBadge.get_summary_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        summary.size.should == 1
        summary[0].should == {
          :first_name => 'First',
          :last_name => 'Last',
          'badge_none' => '',
          'badge_earnt' => '2000-01-02',
        }
      end

      it "Activity badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=summary&section=beavers&sectionid=1&termid=2&type=activity", :body => @data, :content_type => 'application/json')
        summary = Osm::ActivityBadge.get_summary_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        summary.size.should == 1
        summary[0].should == {
          :first_name => 'First',
          :last_name => 'Last',
          'badge_none' => '',
          'badge_earnt' => '2000-01-02',
        }
      end
    end

  end

end
