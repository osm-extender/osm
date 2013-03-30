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
      :completed => 4,
      :awarded => 3,
      :awarded_date => Date.new(2000, 1, 2),
      :requirements => {},
      :section_id => 2,
      :badge => Osm::Badge.new(:osm_key => 'key'),
    )

    data.member_id.should == 1
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
      :requirements => {'a_1' => 'x', 'a_2' => 'a', 'b_1' => 'yes', 'b_2' => '2000-01-02'}
    )
    data.total_gained.should == 3
  end

  it "Get total requirements met in each section for a member" do
    badge = Osm::Badge.new(
      :needed_from_section => {'a' => 1, 'b' => 2},
      :requirements => [
        Osm::Badge::Requirement.new(:field => 'a_1'),
        Osm::Badge::Requirement.new(:field => 'a_2'),
        Osm::Badge::Requirement.new(:field => 'b_1'),
        Osm::Badge::Requirement.new(:field => 'b_2'),
      ]
    )
    data = Osm::Badge::Data.new(
      :badge => badge,
      :requirements => {'a_1' => 'x', 'a_2' => '', 'b_1' => 'yes', 'b_2' => '2000-01-02'}
    )
    data.gained_in_sections.should == {'a' => 0, 'b' => 2}
  end

  it "Get number of sections met for a member" do
    badge = Osm::Badge.new(
      :needed_from_section => {'a' => 1, 'b' => 2},
      :requirements => [
        Osm::Badge::Requirement.new(:field => 'a_1'),
        Osm::Badge::Requirement.new(:field => 'a_2'),
        Osm::Badge::Requirement.new(:field => 'b_1'),
        Osm::Badge::Requirement.new(:field => 'b_2'),
      ]
    )
    data = Osm::Badge::Data.new(
      :badge => badge,
      :requirements => {'a_1' => 'x', 'a_2' => '', 'b_1' => 'yes', 'b_2' => '2000-01-02'}
    )
    data.sections_gained.should == 1
  end

  it "Works out if the badge is due" do
    Osm::Badge::Data.new(:completed => 0, :awarded => 0).due?.should be_false
    Osm::Badge::Data.new(:completed => 1, :awarded => 0).due?.should be_true
    Osm::Badge::Data.new(:completed => 2, :awarded => 2).due?.should be_false
    Osm::Badge::Data.new(:completed => 2, :awarded => 1).due?.should be_true
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
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=challenge&sectionid=1&section=beavers&termid=2", :body => @data)
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
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=staged&sectionid=1&section=beavers&termid=2", :body => @data)
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
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=activity&sectionid=1&section=beavers&termid=2", :body => @data)
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
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=core&section=beavers&c=badge&sectionid=1", :body => @data)
        datas = Osm::CoreBadge.new(:osm_key => 'badge').get_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.completed.should == 2
        data.awarded.should == 1
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge.osm_key.should == 'badge'
      end

      it "Challenge badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=challenge&section=beavers&c=badge&sectionid=1", :body => @data)
        datas = Osm::ChallengeBadge.new(:osm_key => 'badge').get_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.completed.should == 2
        data.awarded.should == 1
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge.osm_key.should == 'badge'
      end

      it "Staged badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=staged&section=beavers&c=badge&sectionid=1", :body => @data)
        datas = Osm::StagedBadge.new(:osm_key => 'badge').get_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
        data.completed.should == 2
        data.awarded.should == 1
        data.awarded_date.should == Date.new(2000, 1, 2)
        data.requirements.should == {'a_1' => 'd'}
        data.section_id.should == 1
        data.badge.osm_key.should == 'badge'
      end

      it "Activity badge" do
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?termid=2&type=activity&section=beavers&c=badge&sectionid=1", :body => @data)
        datas = Osm::ActivityBadge.new(:osm_key => 'badge').get_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
        datas.size.should == 1
        data = datas[0]
        data.member_id.should == 3
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
        @post_data = {
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

        @body_data = {'sid' => '1', 'a' => '2', 'b' => '2'}
      end

      it "Core badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
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

        url = "https://www.onlinescoutmanager.co.uk/challenges.php?type=core&section=beavers"
        HTTParty.should_receive(:post).with(url, {:body => @post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.requirements['a'] = '2'
        data.update(@api).should be_true
      end

      it "Challenge badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
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

        url = "https://www.onlinescoutmanager.co.uk/challenges.php?type=challenge&section=beavers"
        HTTParty.should_receive(:post).with(url, {:body => @post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.requirements['a'] = '2'
        data.update(@api).should be_true
      end

      it "Staged badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
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

        url = "https://www.onlinescoutmanager.co.uk/challenges.php?type=staged&section=beavers"
        HTTParty.should_receive(:post).with(url, {:body => @post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.requirements['a'] = '2'
        data.update(@api).should be_true
      end

      it "Activity badge" do
        data = Osm::Badge::Data.new(
          :member_id => 1,
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

        url = "https://www.onlinescoutmanager.co.uk/challenges.php?type=activity&section=beavers"
        HTTParty.should_receive(:post).with(url, {:body => @post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

        data.requirements['a'] = '2'
        data.update(@api).should be_true
      end

    end

  end

end
