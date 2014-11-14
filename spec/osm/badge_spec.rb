# encoding: utf-8
require 'spec_helper'

describe "Badge" do

  describe "Create" do

    before :each do
      @badge_options = {
        :name => 'name',
        :identifier => '12_3',
        :id => 12,
        :version => 3,
        :group_name => '',
        :latest => true,
        :sharing => :draft,
        :user_id => 4,
        :levels => [1, 2, 3],
        :requirement_notes => 'notes',
        :requirements => [],
        :modules => [{}],
        :min_modules_required => 5,
        :min_fields_required => 6,
        :add_columns_to_module => 7,
        :level_field => 8,
        :requires_modules => [['A'], ['B', 'C']],
        :show_level_letters => true,
      }
    end

    it "Attributes set" do
      badge = Osm::Badge.new(@badge_options)
      badge.name.should == 'name'
      badge.identifier.should == '12_3'
      badge.id.should == 12
      badge.version.should == 3
      badge.group_name.should == ''
      badge.latest.should be_true
      badge.sharing.should == :draft
      badge.user_id.should == 4
      badge.levels.should == [1, 2, 3]
      badge.requirement_notes.should == 'notes'
      badge.requirements.should == []
      badge.modules.should == [{}]
      badge.min_modules_required.should == 5
      badge.min_fields_required.should == 6
      badge.add_columns_to_module.should == 7
      badge.level_field.should == 8
      badge.requires_modules.should == [['A'], ['B', 'C']]
      badge.show_level_letters.should == true
      badge.valid?.should be_true
    end

    it "Valid with nil for levels" do
      badge = Osm::Badge.new(@badge_options.merge(levels: nil))
      badge.levels.should be_nil
      badge.valid?.should be_true
    end

    it "Valid with nil for level_field" do
      badge = Osm::Badge.new(@badge_options.merge(level_field: nil))
      badge.level_field.should be_nil
      badge.valid?.should be_true
    end
    
    it "Valid with nil for add_columns_to_module" do
      badge = Osm::Badge.new(@badge_options.merge(add_columns_to_module: nil))
      badge.add_columns_to_module.should be_nil
      badge.valid?.should be_true
    end

  end

  it "Create Requirement" do
    requirement = Osm::Badge::Requirement.new(
      :name => 'name',
      :description => 'description',
      :module_letter => 'a',
      :field => 1,
      :editable => true,
      :badge => Osm::Badge.new(:identifier => 'key'),
    )

    requirement.name.should == 'name'
    requirement.description.should == 'description'
    requirement.module_letter.should == 'a'
    requirement.field.should == 1
    requirement.editable.should be_true
    requirement.badge.identifier.should == 'key'
    requirement.valid?.should be_true
  end

  it "Works out if we add columns to this badge" do
    Osm::Badge.new(add_columns_to_module: 123).add_columns?.should be_true
    Osm::Badge.new(add_columns_to_module: nil).add_columns?.should be_false
  end

  it "Produces a map of module letter <-> module id" do
    badge = Osm::Badge.new(modules: [
      {module_id: 2, module_letter: 'c'},
      {module_id: 10, module_letter: 'b'},
      {module_id: 1, module_letter: 'a'}
    ])

    badge.module_map.should == {1=>'a', 10=>'b', 2=>'c', 'a'=>1, 'b'=>10, 'c'=>2}
  end

  it "Gets the number of requirements needed per module" do
    badge = Osm::Badge.new(modules: [
      {module_id: 2, module_letter: 'c', min_required: 5},
      {module_id: 10, module_letter: 'b', min_required: 4},
      {module_id: 1, module_letter: 'a', min_required: 3}
    ])

    badge.needed_per_module.should == {'a'=>3, 'b'=>4, 'c'=>5, 2=>5, 10=>4, 1=>3}
  end

  it "Produces a list of modules" do
    badge = Osm::Badge.new(modules: [
      {module_id: 2, module_letter: 'c'},
      {module_id: 10, module_letter: 'b'},
      {module_id: 1, module_letter: 'a'}
    ])

    badge.module_letters.should == ['a', 'b', 'c']
    badge.module_ids.should == [1, 2, 10]
  end


  it "Create Data" do
    data = Osm::Badge::Data.new(
      :member_id => 1,
      :first_name => 'First',
      :last_name => 'Last',
      :due => 4,
      :awarded => 3,
      :awarded_date => Date.new(2000, 1, 2),
      :requirements => {},
      :section_id => 2,
      :badge => Osm::Badge.new(:identifier => 'key'),
    )

    data.member_id.should == 1
    data.first_name.should == 'First'
    data.last_name.should == 'Last'
    data.due.should == 4
    data.awarded.should == 3
    data.awarded_date.should == Date.new(2000, 1, 2)
    data.requirements.should == {}
    data.section_id.should == 2
    data.badge.identifier.should == 'key'
    data.valid?.should be_true
  end


  it "Compare badges by name then id then version (descending)" do
    b1 = Osm::Badge.new(:name => 'A', :id => 1, :version => 1)
    b2 = Osm::Badge.new(:name => 'B', :id => 1, :version => 1)
    b3 = Osm::Badge.new(:name => 'B', :id => 2, :version => 2)
    b4 = Osm::Badge.new(:name => 'B', :id => 2, :version => 1)
    badges = [b3, b1, b4, b2]
    badges.sort.should == [b1, b2, b3, b4]
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


  it "Works out if a requirement has been met" do
    data = Osm::Badge::Data.new(requirements: {1 => ''}).requirement_met?(1).should be_false
    data = Osm::Badge::Data.new(requirements: {1 => 'xStuff'}).requirement_met?(1).should be_false
    data = Osm::Badge::Data.new(requirements: {1 => '0'}).requirement_met?(1).should be_false
    data = Osm::Badge::Data.new(requirements: {1 => 0}).requirement_met?(1).should be_false
    data = Osm::Badge::Data.new(requirements: {}).requirement_met?(1).should be_false
    data = Osm::Badge::Data.new(requirements: {1 => 'Stuff'}).requirement_met?(1).should be_true
    data = Osm::Badge::Data.new(requirements: {1 => '1'}).requirement_met?(1).should be_true
    data = Osm::Badge::Data.new(requirements: {1 => 1}).requirement_met?(1).should be_true
  end


  it "Get total requirements gained for a member" do
    data = Osm::Badge::Data.new(
      :badge => Osm::Badge.new(
        :requirements => [
          Osm::Badge::Requirement.new(field: 1),
          Osm::Badge::Requirement.new(field: 2),
          Osm::Badge::Requirement.new(field: 3),
          Osm::Badge::Requirement.new(field: 4),
          Osm::Badge::Requirement.new(field: 5),
          Osm::Badge::Requirement.new(field: 6),
          Osm::Badge::Requirement.new(field: 7),
          Osm::Badge::Requirement.new(field: 8),
          Osm::Badge::Requirement.new(field: 9),
        ]
      ),
      :requirements => {
        1 => 'a',
        2 => 'yes',
        3 => '2000-01-02',
        4 => 1,
        5 => 'x',
        6 => 'xYES',
        7 => '',
        8 => nil,
        9 => 0,
      }
    )
    data.total_gained.should == 4
  end

  it "Get total requirements met in each module for a member" do
    badge = Osm::Badge.new(
      :needed_from_section => {'a' => 1, 'b' => 2},
      :requirements => [
        Osm::Badge::Requirement.new(:module_letter=> 'a', :field => '1'),
        Osm::Badge::Requirement.new(:module_letter=> 'a', :field => '2'),
        Osm::Badge::Requirement.new(:module_letter=> 'b', :field => '3'),
        Osm::Badge::Requirement.new(:module_letter=> 'b', :field => '4'),
        Osm::Badge::Requirement.new(:module_letter=> 'c', :field => '5'),
        Osm::Badge::Requirement.new(:module_letter=> 'c', :field => '6'),
      ],
      :modules => [
        { module_letter: 'a', module_id: 100 },
        { module_letter: 'b', module_id: 200 },
        { module_letter: 'c', module_id: 300 }
      ]
    )
    data = Osm::Badge::Data.new(
      :badge => badge,
      :requirements => { 1=>'x', 2=>'', 3=>'yes', 4=>'2000-01-02', 5=>1 }
    )
    data.gained_in_modules.should == {'a'=>0, 'b'=>2, 'c'=>1, 100=>0, 200=>2, 300=>1}
  end

  it "Get modules met for a member" do
    badge = Osm::Badge.new(
      :requirements => [
        Osm::Badge::Requirement.new(:module_letter=> 'a', :field => '1'),
        Osm::Badge::Requirement.new(:module_letter=> 'a', :field => '2'),
        Osm::Badge::Requirement.new(:module_letter=> 'b', :field => '3'),
        Osm::Badge::Requirement.new(:module_letter=> 'b', :field => '4'),
        Osm::Badge::Requirement.new(:module_letter=> 'c', :field => '5'),
      ],
      :modules => [
        { module_letter: 'a', module_id: 1000, min_required: 1 },
        { module_letter: 'b', module_id: 2000, min_required: 2 },
        { module_letter: 'c', module_id: 3000, min_required: 1 }
      ]
    )
    data = Osm::Badge::Data.new(
      :badge => badge,
      :requirements => {1=>'x', 2=>'', 3=>'yes', 4=>'2000-01-02', 5=>'yes'}
    )
    data.modules_gained.should == ['b', 'c']
  end

  describe "Works out if the badge has been earnt" do
    it "Staged" do
      badge = Osm::StagedBadge.new(levels: [0, 1, 2, 3])
      data = Osm::Badge::Data.new(:awarded => 2, :badge => badge)

      data.stub(:earnt) { 1 }
      data.earnt?.should be_false

      data.stub(:earnt) { 2 }
      data.earnt?.should be_false

      data.stub(:earnt) { 3 }
      data.earnt?.should be_true
    end

    it "Non staged" do
      badge = Osm::ActivityBadge.new(
        :min_modules_required => 0,
        :min_fields_required => 0,
        :modules => [
          {module_id: 1, module_letter: 'a', min_required: 2},
          {module_id: 2, module_letter: 'b', min_required: 1},
          {module_id: 3, module_letter: 'c', min_required: 1},
        ],
        :badges_required => [],
        :fields_required => [],
        :requirements => [
          Osm::Badge::Requirement.new(badge: badge, module_letter: 'a', field: 10),
          Osm::Badge::Requirement.new(badge: badge, module_letter: 'a', field: 11),
          Osm::Badge::Requirement.new(badge: badge, module_letter: 'b', field: 20),
          Osm::Badge::Requirement.new(badge: badge, module_letter: 'b', field: 21),
          Osm::Badge::Requirement.new(badge: badge, module_letter: 'c', field: 30),
          Osm::Badge::Requirement.new(badge: badge, module_letter: 'c', field: 31),
        ],
      )

      data = Osm::Badge::Data.new(:due => 1, :awarded => 1, :badge => badge)
      data.earnt?.should be_false

      data = Osm::Badge::Data.new(:due => 1, :awarded => 0, :badge => badge)
      data.earnt?.should be_true


      # Number of modules required
      this_badge = badge.clone
      this_badge.min_modules_required = 2

      data = Osm::Badge::Data.new(:requirements => {10=>'y', 11=>'y', 20=>'y'}, :due => 0, :awarded => 0, :badge => this_badge)
      data.earnt?.should be_true

      data = Osm::Badge::Data.new(:requirements => {10=>'y', 11=>'y', 20=>'x'}, :due => 0, :awarded => 0, :badge => this_badge)
      data.earnt?.should be_false


      # Number of requirements needed
      this_badge = badge.clone
      this_badge.min_modules_required = 0
      this_badge.min_fields_required = 2

      data = Osm::Badge::Data.new(:requirements => {10=>'y', 11=>'y', 20=>'y'}, :due => 0, :awarded => 0, :badge => this_badge)
      data.earnt?.should be_true

      data = Osm::Badge::Data.new(:requirements => {10=>'y', 11=>'x', 20=>'y'}, :due => 0, :awarded => 0, :badge => this_badge)
      data.earnt?.should be_true

      data = Osm::Badge::Data.new(:requirements => {10=>'y', 11=>'x', 20=>'x'}, :due => 0, :awarded => 0, :badge => this_badge)
      data.earnt?.should be_false


      # Module combinations
      this_badge = badge.clone
      this_badge.requires_modules = [['a'], ['b', 'c']]

      data = Osm::Badge::Data.new(:requirements => {10=>'x', 11=>'x', 20=>'x', 30=>'x'}, :due => 0, :awarded => 0, :badge => this_badge)
      data.earnt?.should be_false

      data = Osm::Badge::Data.new(:requirements => {10=>'y', 11=>'y', 20=>'x', 30=>'x'}, :due => 0, :awarded => 0, :badge => this_badge)
      data.earnt?.should be_false

      data = Osm::Badge::Data.new(:requirements => {10=>'y', 11=>'y', 20=>'y', 30=>'x'}, :due => 0, :awarded => 0, :badge => this_badge)
      data.earnt?.should be_true

      data = Osm::Badge::Data.new(:requirements => {10=>'y', 11=>'y', 20=>'x', 30=>'y'}, :due => 0, :awarded => 0, :badge => this_badge)
      data.earnt?.should be_true
    end
  end

  describe "Works out what level of a badge has been earnt" do

    it "Staged (activity)" do
      badge = Osm::StagedBadge.new(
        :levels => [0, 1, 2, 3],
        :min_modules_required => 0,
        :min_requirements_completed => 0,
        :modules => [
          {module_id: 1, module_letter: 'a', min_required: 1},
          {module_id: 2, module_letter: 'b', min_required: 1},
          {module_id: 3, module_letter: 'c', min_required: 1},
        ],
        :show_level_letters => true,
      )
      badge.requirements = [
        Osm::Badge::Requirement.new(badge: badge, module_letter: 'a', field: 10),
        Osm::Badge::Requirement.new(badge: badge, module_letter: 'a', field: 11),
        Osm::Badge::Requirement.new(badge: badge, module_letter: 'b', field: 20),
        Osm::Badge::Requirement.new(badge: badge, module_letter: 'b', field: 21),
        Osm::Badge::Requirement.new(badge: badge, module_letter: 'c', field: 30),
        Osm::Badge::Requirement.new(badge: badge, module_letter: 'c', field: 31),
      ]

      requirements = {10=>'',11=>'',20=>'',21=>'',30=>'',31=>''}
      data = Osm::Badge::Data.new(requirements: requirements, badge: badge)
      data.earnt.should == 0

      requirements = {10=>'y',11=>'',20=>'',21=>'',30=>'',31=>''}
      data = Osm::Badge::Data.new(requirements: requirements, badge: badge)
      data.earnt.should == 1

      requirements = {10=>'y',11=>'',20=>'',21=>'y',30=>'',31=>''}
      data = Osm::Badge::Data.new(requirements: requirements, badge: badge)
      data.earnt.should == 2

      requirements = {10=>'',11=>'',20=>'',21=>'y',30=>'',31=>''}
      data = Osm::Badge::Data.new(requirements: requirements, badge: badge)
      data.earnt.should == 2

      requirements = {10=>'y',11=>'',20=>'y',21=>'',30=>'y',31=>''}
      data = Osm::Badge::Data.new(requirements: requirements, badge: badge)
      data.earnt.should == 3
    end

    it "Staged (count)" do
      badge = Osm::StagedBadge.new(
        :levels => [0,1,2,3,4,5,10,15,20],
        :show_level_letters => false,
        :level_field => 3000,
        :requirements => []
      )

      Osm::Badge::Data.new(:requirements => {3000 => 9},   :badge => badge).earnt.should == 5
      Osm::Badge::Data.new(:requirements => {3000 => 10},  :badge => badge).earnt.should == 10
      Osm::Badge::Data.new(:requirements => {3000 => 11},  :badge => badge).earnt.should == 10
      Osm::Badge::Data.new(:requirements => {3000 => 999}, :badge => badge).earnt.should == 20
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
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {1 => 'Yes', 2 => ''}).started?.should be_true
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {1 => 'Yes', 2 => ''}, :due => 1).started?.should be_false
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {1 => 'xNo', 2 => ''}).started?.should be_false
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {1 => '', 2 => ''}).started?.should be_false

    # Staged Activity Badge
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new(
        :levels => [0,1,2],
        :show_level_letters => true,
        :requirements => [
          Osm::Badge::Requirement.new(:module_letter => 'a', :field => 1000),
          Osm::Badge::Requirement.new(:module_letter => 'b', :field => 2000),
          Osm::Badge::Requirement.new(:module_letter => 'b', :field => 2001),
        ]
      ),
      :requirements => {1000 => 'Yes', 2000 => 'Yes', 2001 => ''},
      :due => 1,
    ).started?.should be_true

    # Staged Count Badge
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new(:levels => [0,1,2,3,4,5,10,15,20], :show_level_letters => false, :level_field => 1000),
      :requirements => {1000 => 5, 2000 => '5', 3000 => ''},
      :due => 5,
      :awarded => 4,
    ).started?.should be_false # Finished lvl 5 & not started lvl 10
    Osm::Badge::Data.new(
      :badge => Osm::StagedBadge.new(:levels => [0,1,2,3,4,5,10,15,20], :show_level_letters => false, :level_field => 1000),
      :requirements => {1000 => 6, 2000 => '6', 3000 => ''},
      :due => 5,
      :awarded => 3,
    ).started?.should be_true # Finished lvl 5 & started lvl 10
  end

  it "Works out what stage of the badge has been started" do
    # Non-Staged badges (0 or 1)
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {10 => 'Yes', 11 => ''}).started.should == 1
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {10 => 'Yes', 11 => ''}, :due => 1).started.should == 0
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {10 => 'xNo', 11 => ''}).started.should == 0
    Osm::Badge::Data.new(:badge => Osm::CoreBadge.new, :requirements => {10 => '', 11 => ''}).started.should == 0


    # Staged Activity
    staged_activity = Osm::StagedBadge.new(
      :levels => [0,1,2],
      :show_level_letters => true,
      :requirements => [
        Osm::Badge::Requirement.new(:module_letter => 'a', :field => 100),
        Osm::Badge::Requirement.new(:module_letter => 'b', :field => 200),
        Osm::Badge::Requirement.new(:module_letter => 'b', :field => 201),
      ]
    )

    Osm::Badge::Data.new(
      :badge => staged_activity,
      :requirements => {100 => 'Yes', 200 => 'Yes', 201 => ''},
      :due => 1,
    ).started.should == 2
    Osm::Badge::Data.new(
      :badge => staged_activity,
      :requirements => {100 => 'Yes', 200 => 'Yes', 201 => ''},
      :due => 1,
    ).started.should == 2
    Osm::Badge::Data.new(
      :badge => staged_activity,
      :requirements => {},
      :due => 2,
    ).started.should == 0 # No more stages to do


    # Staged count
    staged_count = Osm::StagedBadge.new(
      :levels => [0,1,2,3,4,5,10,15,20],
      :show_level_letters => false,
      :level_field => 3000,
      :requirements => []
    )

    Osm::Badge::Data.new(
      :badge => staged_count,
      :requirements => {3000 => 7},
      :due => 5,
    ).started.should == 10
    Osm::Badge::Data.new(
      :badge => staged_count,
      :requirements => {3000 => 3},
      :due => 3,
    ).started.should == 0
  end

  describe "Using the OSM API" do

    describe "Get Badges" do

      before :each do
        @badge_data = {
          'badgeOrder' => '123_0',
          'details' => {
            '123_0' => {
              'badge_id' => '123',
              'badge_id_version' => '123_0',
              'badge_identifier' => '123_0',
              'badge_order' => '4',
              'badge_version' => '0',
              'config' => '{"numModulesRequired":1,"shownumbers":true}',
              'description' => 'b_req_notes',
              'group_name' => '',
              'lastupdated' => '2014-09-14 02:32:05',
              'latest' => '1',
              'name' => 'b_name',
              'picture' => 'path/to/image.gif',
              'portal_config' => '{"position":{"x":58,"y":282,"w":20,"h":20,"r":6}}',
              'sharing' => 'default-locked',
              'shortname' => '00',
              'userid' => '0',
            }
          },
          'structure' => {
            '123_0' => [
              {
                'rows' => [
                  {"name" => "First name","field" => "firstname","width" => "120px"},
                  {"name" => "Last name","field" => "lastname","width" => "120px"},
                  {"name" => "Done","field" => "completed","width" => "70px","formatter" => "doneFormatter"},
                  {"name" => "Awarded","field" => "awardeddate","width" => "100px","formatter" => "dueFormatter"}
                ],
                "numactivities" => "23",
                "noscroll" => true
               },{
                'rows' => [
                  {"name" => "r_name","field" => "2345","width" => "80px","formatter" => "cellFormatter","tooltip" => "r_description","editable" => "true","module"=>"a"}
                ]
              }
            ],
          }
        }
        @badge_data = @badge_data.to_json

        @module_data = {'items' => [
          {
            'badge_id' => '123',
            'badge_version' => '0',
            'module_id' => '234',
            'module_letter' => 'a',
            'num_required' => '',
            'custom_columns' => '',
            'completed_into_column_id' => '',
            'numeric_into_column_id' => '',
            'add_column_id_to_numeric' => '',
          },
        ]}
        @module_data = @module_data.to_json
      end

      urls = {
        Osm::CoreBadge => 'https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=4&term_id=2&section_id=1',
        Osm::ChallengeBadge => 'https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=1&term_id=2&section_id=1',
        Osm::StagedBadge => 'https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=3&term_id=2&section_id=1',
        Osm::ActivityBadge => 'https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=2&term_id=2&section_id=1',
      }
      urls.each do |type, url|
        it type.type.to_s.titleize do
          FakeWeb.register_uri(:post, url, :body => @badge_data, :content_type => 'application/json')
          FakeWeb.register_uri(:post, 'https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=_getModuleDetails', :body => @module_data, :content_type => 'application/json')
          Osm::Term.stub(:get_current_term_for_section){ Osm::Term.new(:id => 2) }

          badges = type.get_badges_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers))
          badges.size.should == 1
          badge = badges[0]
          badge.name.should == 'b_name'
          badge.requirement_notes.should == 'b_req_notes'
          badge.identifier.should == '123_0'
          badge.id.should == 123
          badge.version.should == 0
          badge.latest.should be_true
          badge.user_id.should == 0
          badge.sharing.should == :default_locked
          badge.requirements.size.should == 1
          badge.min_modules_required.should == 1
          badge.min_fields_required.should == 0
          badge.add_columns_to_module.should == nil
          badge.level_field.should == nil
          badge.requires_modules.should == nil
          badge.fields_required.should == []
          badge.badges_required.should == []
          badge.show_level_letters.should == true
          badge.valid?.should be_true
          requirement = badge.requirements[0]
          requirement.name.should == 'r_name'
          requirement.description.should == 'r_description'
          requirement.field.should == 2345
          requirement.module_letter.should == 'a'
          requirement.editable.should be_true
          requirement.badge.should == badge
          requirement.valid?.should be_true
          badge.modules.should == [
            {
              :badge_id => 123,
              :badge_version => 0,
              :module_id => 234,
              :module_letter => 'a',
              :min_required => 0,
              :custom_columns => 0,
              :completed_into_column => nil,
              :numeric_into_column => nil,
              :add_column_id_to_numeric => nil,
            }
          ]
        end
      end

    end


    it "Get badge data for a section" do
      data = {
        'identifier' => 'scoutid',
        'items' => [{
          'scoutid' => '3',
          'firstname' => 'fn',
          'lastname' => 'ln',
          'completed' => '2',
          'awarded' => '1',
          'awardeddate' => '2000-01-02',
          '2345' => 'd',
        }]
      }
      data = data.to_json

      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=getBadgeRecords&term_id=2&section=beavers&badge_id=123&section_id=1&badge_version=0", :body => data, :content_type => 'application/json')
      datas = Osm::CoreBadge.new(:id => 123, :version => 0).get_data_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
      datas.size.should == 1
      data = datas[0]
      data.member_id.should == 3
      data.first_name.should == 'fn'
      data.last_name.should == 'ln'
      data.due.should == 2
      data.awarded.should == 1
      data.awarded_date.should == Date.new(2000, 1, 2)
      data.requirements.should == {2345 => 'd'}
      data.section_id.should == 1
      data.badge.id.should == 123
    end

    describe "Update badge data in OSM" do

      before :each do
        @update_post_data = {
          'apiid' => @CONFIGURATION[:api][:osm][:id],
          'token' => @CONFIGURATION[:api][:osm][:token],
          'userid' => 'user_id',
          'secret' => 'secret',
          'scoutid' => 1,
          'section_id' => 2,
          'badge_id' => 123,
          'badge_version' => 0,
          'field' => 2345,
          'value' => '2'
        }
        @update_body_data = {'scoutid' => '1', '2345' => '2', 'completed' => '0', 'awarded' => '0', 'firstname' => 'fn', 'lastname' => 'ln'}

        @data = Osm::Badge::Data.new(
          :member_id => 1,
          :first_name => 'fn',
          :last_name => 'ln',
          :section_id => 2,
          :requirements => {2345 => '1', 6789 => '2'},
          :badge => Osm::CoreBadge.new(
            :id => 123,
            :version => 0,
            :requirements => [
              Osm::Badge::Requirement.new(:field => 2345, :editable => true),
              Osm::Badge::Requirement.new(:field => 6789, :editable => true),
            ]),
          :due => 0,
        )
     end

     it "Success (requirmeent, due & awarded)" do
        date = Date.new(2000, 1, 2)
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=updateSingleRecord', {:body => @update_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@update_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }
        @data.should_receive(:mark_awarded).with(@api, date, 1) { true }
        @data.should_receive(:mark_due).with(@api, 1) { true }

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        @data.update(@api).should be_true
      end

      it "Success (just requirement)" do
        date = Date.new(2000, 1, 2)
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=updateSingleRecord', {:body => @update_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@update_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }
        @data.should_not_receive(:mark_awarded)
        @data.should_not_receive(:mark_due)

        @data.requirements[2345] = '2'
        @data.update(@api).should be_true
      end

      it "Success (just due)" do
        date = Date.new(2000, 1, 2)
        HTTParty.should_not_receive(:post)
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }
        @data.should_not_receive(:mark_awarded)
        @data.should_receive(:mark_due).with(@api, 1) { true }

        @data.due = 1
        @data.update(@api).should be_true
      end

      it "Success (just awarded)" do
        date = Date.new(2000, 1, 2)
        HTTParty.should_not_receive(:post)
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }
        @data.should_receive(:mark_awarded).with(@api, date, 1) { true }
        @data.should_not_receive(:mark_due).with(@api, 1) { true }

        @data.awarded = 1
        @data.awarded_date = date
        @data.update(@api).should be_true
      end

      it "Failed (requirement)" do
        date = Date.new(2000, 1, 2)
        @update_body_data['2345'] = '1'
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=updateSingleRecord', {:body => @update_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@update_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }
        @data.should_receive(:mark_awarded).with(@api, date, 1) { true }
        @data.should_receive(:mark_due).with(@api, 1) { true }

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        @data.update(@api).should be_false
      end

      it "Failed (due)" do
        date = Date.new(2000, 1, 2)
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=updateSingleRecord', {:body => @update_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@update_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }
        @data.should_receive(:mark_awarded).with(@api, date, 1) { true }
        @data.should_receive(:mark_due).with(@api, 1) { false }

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        @data.update(@api).should be_false
      end

      it "Failed (awarded)" do
        date = Date.new(2000, 1, 2)
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=updateSingleRecord', {:body => @update_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>@update_body_data.to_json}) }
        Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }
        @data.should_receive(:mark_awarded).with(@api, date, 1) { false }
        @data.should_receive(:mark_due).with(@api, 1) { true }

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        @data.update(@api).should be_false
      end

    end


    it "Mark badge awarded" do

      awarded_post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'date' => '2000-01-02',
        'sectionid' => 2,
        'entries' => '[{"badge_id":"123","badge_version":"0","scout_id":"1","level":"1"}]',
      }
      awarded_body_data = {'scoutid'=>'1', 'completed'=>'1', 'awarded' => '1', 'awardeddate'=>'2000-01-02', 'firstname' => 'fn', 'lastname' => 'ln'}
      awarded_url = "https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=awardBadge"

      data = Osm::Badge::Data.new(
        :member_id => 1,
        :section_id => 2,
        :badge => Osm::CoreBadge.new(
          :id => 123,
          :version => 0
        )
      )

      HTTParty.should_receive(:post).with(awarded_url, {:body => awarded_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>awarded_body_data.to_json}) }
      Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

      data.mark_awarded(@api, Date.new(2000, 1, 2), 1).should be_true
    end

    it "Mark badge due" do

      awarded_post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'section_id' => 2,
        'badge_id' => 123,
        'badge_version' => 0,
        'scoutid' => 1,
        'level' => 1
      }
      awarded_body_data = {'scoutid'=>'1', 'completed'=>'1', 'awarded' => '1', 'awardeddate'=>'2000-01-02', 'firstname' => 'fn', 'lastname' => 'ln'}
      awarded_url = "https://www.onlinescoutmanager.co.uk/ext/badges/records/?action=overrideCompletion"

      data = Osm::Badge::Data.new(
        :member_id => 1,
        :section_id => 2,
        :badge => Osm::CoreBadge.new(
          :id => 123,
          :version => 0
        )
      )

      HTTParty.should_receive(:post).with(awarded_url, {:body => awarded_post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>awarded_body_data.to_json}) }
      Osm::Section.stub(:get) { Osm::Section.new(:id => 2, :type => :beavers) }

      data.mark_due(@api, 1).should be_true
    end

    it "Get summary data for a section" do

      data = {
        'identifier' => 'scout_id',
        'items' => [
          {
            'firstname' => 'First',
            'lastname' => 'Last',
            'scout_id' => 1,
            '90_0' => nil,
            '91_0' => '',
            '92_0' => 'Started',
            '93_0' => 'Due',
            '94_0' => 'Due Lvl 3',
            '95_0' => 'Awarded',
            '96_0' => 'Awarded Lvl 2',
            '97_0' => '01/02/2003',
            '98_0' => '02/03/2004 (Lvl 1)',
          }
        ]
      }
      data = data.to_json

      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/ext/badges/records/summary/?action=get&mode=verbose&section=beavers&sectionid=1&termid=2", :body => data, :content_type => 'application/json')
      summary = Osm::Badge.get_summary_for_section(@api, Osm::Section.new(:id => 1, :type => :beavers), 2)
      summary.size.should == 1
      summary[0].should == {
        :first_name => 'First',
        :last_name => 'Last',
        :name => 'First Last',
        :member_id => 1,
        '92_0' => :started,
        '93_0' => :due,
        '94_0' => :due,
        '94_0_level' => 3,
        '95_0' => :awarded,
        '96_0' => :awarded,
        '96_0_level' => 2,
        '97_0' => :awarded,
        '97_0_date' => Date.new(2003, 2, 1),
        '98_0' => :awarded,
        '98_0_date' => Date.new(2004, 3, 2),
        '98_0_level' => 1,
      }
    end

  end

end
