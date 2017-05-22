# encoding: utf-8
require 'spec_helper'

describe "Badge" do

  describe "Create" do

    before :each do
      @badge_options = {
        name: 'name',
        identifier: '12_3',
        id: 12,
        version: 3,
        group_name: '',
        latest: true,
        sharing: :draft,
        user_id: 4,
        levels: [1, 2, 3],
        requirement_notes: 'notes',
        requirements: [],
        modules: [],
        min_modules_required: 5,
        min_requirements_required: 6,
        add_columns_to_module: 7,
        level_requirement: 8,
        requires_modules: [['A'], ['B', 'C']],
        show_level_letters: true,
      }
    end

    it "Attributes set" do
      badge = Osm::Badge.new(@badge_options)
      expect(badge.name).to eq('name')
      expect(badge.identifier).to eq('12_3')
      expect(badge.id).to eq(12)
      expect(badge.version).to eq(3)
      expect(badge.group_name).to eq('')
      expect(badge.latest).to eq(true)
      expect(badge.sharing).to eq(:draft)
      expect(badge.user_id).to eq(4)
      expect(badge.levels).to eq([1, 2, 3])
      expect(badge.requirement_notes).to eq('notes')
      expect(badge.requirements).to eq([])
      expect(badge.modules).to eq([])
      expect(badge.min_modules_required).to eq(5)
      expect(badge.min_requirements_required).to eq(6)
      expect(badge.add_columns_to_module).to eq(7)
      expect(badge.level_requirement).to eq(8)
      expect(badge.requires_modules).to eq([['A'], ['B', 'C']])
      expect(badge.show_level_letters).to eq(true)
      expect(badge.valid?).to eq(true)
    end

    it "Valid with nil for levels" do
      badge = Osm::Badge.new(@badge_options.merge(levels: nil))
      expect(badge.levels).to be_nil
      expect(badge.valid?).to eq(true)
    end

    it "Valid with nil for level_requirement" do
      badge = Osm::Badge.new(@badge_options.merge(level_requirement: nil))
      expect(badge.level_requirement).to be_nil
      expect(badge.valid?).to eq(true)
    end
    
    it "Valid with nil for add_columns_to_module" do
      badge = Osm::Badge.new(@badge_options.merge(add_columns_to_module: nil))
      expect(badge.add_columns_to_module).to be_nil
      expect(badge.valid?).to eq(true)
    end

  end

  it "Create Requirement" do
    m = Osm::Badge::RequirementModule.new
    requirement = Osm::Badge::Requirement.new(
      name: 'name',
      description: 'description',
      mod: m,
      id: 1,
      editable: true,
      badge: Osm::Badge.new(identifier: 'key'),
    )

    expect(requirement.name).to eq('name')
    expect(requirement.description).to eq('description')
    expect(requirement.mod).to eq(m)
    expect(requirement.id).to eq(1)
    expect(requirement.editable).to eq(true)
    expect(requirement.badge.identifier).to eq('key')
    expect(requirement.valid?).to eq(true)
  end

  it "Create RequirementModule" do
    b = Osm::Badge.new
    m = Osm::Badge::RequirementModule.new(
      badge: b,
      id: 567,
      letter: 'a',
      min_required: 1,
      custom_columns: 2,
      completed_into_column: 3,
      numeric_into_column: 4,
      add_column_id_to_numeric: 5,
    )

    expect(m.badge).to eq(b)
    expect(m.id).to eq(567)
    expect(m.letter).to eq('a')
    expect(m.min_required).to eq(1)
    expect(m.custom_columns).to eq(2)
    expect(m.completed_into_column).to eq(3)
    expect(m.numeric_into_column).to eq(4)
    expect(m.add_column_id_to_numeric).to eq(5)
    expect(m.valid?).to eq(true)
  end

  it "Works out if we add columns to this badge" do
    expect(Osm::Badge.new(add_columns_to_module: 123).add_columns?).to eq(true)
    expect(Osm::Badge.new(add_columns_to_module: nil).add_columns?).to eq(false)
  end

  it "Produces a map of module letter <-> module id" do
    badge = Osm::Badge.new(modules: [
      Osm::Badge::RequirementModule.new(id: 2, letter: 'c'),
      Osm::Badge::RequirementModule.new(id: 10, letter: 'b'),
      Osm::Badge::RequirementModule.new(id: 1, letter: 'a'),
    ])

    expect(badge.module_map).to eq({1=>'a', 10=>'b', 2=>'c', 'a'=>1, 'b'=>10, 'c'=>2})
  end

  it "Gets the number of requirements needed per module" do
    badge = Osm::Badge.new(modules: [
      Osm::Badge::RequirementModule.new(id: 2, letter: 'c', min_required: 5),
      Osm::Badge::RequirementModule.new(id: 10, letter: 'b', min_required: 4),
      Osm::Badge::RequirementModule.new(id: 1, letter: 'a', min_required: 3),
    ])

    expect(badge.needed_per_module).to eq({'a'=>3, 'b'=>4, 'c'=>5, 2=>5, 10=>4, 1=>3})
  end

  it "Produces a list of modules" do
    badge = Osm::Badge.new(modules: [
      Osm::Badge::RequirementModule.new(id: 2, letter: 'c'),
      Osm::Badge::RequirementModule.new(id: 10, letter: 'b'),
      Osm::Badge::RequirementModule.new(id: 1, letter: 'a'),
    ])

    expect(badge.module_letters).to eq(['a', 'b', 'c'])
    expect(badge.module_ids).to eq([1, 2, 10])
  end


  it "Create Data" do
    data = Osm::Badge::Data.new(
      member_id: 1,
      first_name: 'First',
      last_name: 'Last',
      due: 4,
      awarded: 3,
      awarded_date: Date.new(2000, 1, 2),
      requirements: {},
      section_id: 2,
      badge: Osm::Badge.new(identifier: 'key'),
    )

    expect(data.member_id).to eq(1)
    expect(data.first_name).to eq('First')
    expect(data.last_name).to eq('Last')
    expect(data.due).to eq(4)
    expect(data.awarded).to eq(3)
    expect(data.awarded_date).to eq(Date.new(2000, 1, 2))
    expect(data.requirements).to eq({})
    expect(data.section_id).to eq(2)
    expect(data.badge.identifier).to eq('key')
    expect(data.valid?).to eq(true)
  end


  it "Compare badges by name then id then version (descending)" do
    b1 = Osm::Badge.new(name: 'A', id: 1, version: 1)
    b2 = Osm::Badge.new(name: 'B', id: 1, version: 1)
    b3 = Osm::Badge.new(name: 'B', id: 2, version: 2)
    b4 = Osm::Badge.new(name: 'B', id: 2, version: 1)
    badges = [b3, b1, b4, b2]
    expect(badges.sort).to eq([b1, b2, b3, b4])
  end

  it "Compare badge requirements by badge then id" do
    b1 = Osm::Badge::Requirement.new(badge: Osm::Badge.new(name: 'A'), id: 1)
    b2 = Osm::Badge::Requirement.new(badge: Osm::Badge.new(name: 'B'), id: 1)
    b3 = Osm::Badge::Requirement.new(badge: Osm::Badge.new(name: 'B'), id: 2)
    badges = [b3, b1, b2]
    expect(badges.sort).to eq([b1, b2, b3])
  end

  it "Compare badge requirement modules by badge then letter then id" do
    b1 = Osm::Badge::RequirementModule.new(badge: Osm::Badge.new(name: 'A'), letter: 'a', id: 1)
    b2 = Osm::Badge::RequirementModule.new(badge: Osm::Badge.new(name: 'B'), letter: 'a', id: 1)
    b3 = Osm::Badge::RequirementModule.new(badge: Osm::Badge.new(name: 'B'), letter: 'b', id: 1)
    b4 = Osm::Badge::RequirementModule.new(badge: Osm::Badge.new(name: 'B'), letter: 'b', id: 2)
    badges = [b3, b4, b1, b2]
    expect(badges.sort).to eq([b1, b2, b3, b4])
  end

  it "Compare badge data by badge, section_id then member_id" do
    b1 = Osm::Badge::Data.new(badge: Osm::Badge.new(name: 'A'), section_id: 1, member_id: 1)
    b2 = Osm::Badge::Data.new(badge: Osm::Badge.new(name: 'B'), section_id: 1, member_id: 1)
    b3 = Osm::Badge::Data.new(badge: Osm::Badge.new(name: 'B'), section_id: 2, member_id: 1)
    b4 = Osm::Badge::Data.new(badge: Osm::Badge.new(name: 'B'), section_id: 2, member_id: 2)
    badges = [b3, b4, b1, b2]
    expect(badges.sort).to eq([b1, b2, b3, b4])
  end


  it "Works out if a requirement has been met" do
    data = expect(Osm::Badge::Data.new(requirements: {1 => ''}).requirement_met?(1)).to eq(false)
    data = expect(Osm::Badge::Data.new(requirements: {1 => 'xStuff'}).requirement_met?(1)).to eq(false)
    data = expect(Osm::Badge::Data.new(requirements: {1 => '0'}).requirement_met?(1)).to eq(false)
    data = expect(Osm::Badge::Data.new(requirements: {1 => 0}).requirement_met?(1)).to eq(false)
    data = expect(Osm::Badge::Data.new(requirements: {}).requirement_met?(1)).to eq(false)
    data = expect(Osm::Badge::Data.new(requirements: {1 => 'Stuff'}).requirement_met?(1)).to eq(true)
    data = expect(Osm::Badge::Data.new(requirements: {1 => '1'}).requirement_met?(1)).to eq(true)
    data = expect(Osm::Badge::Data.new(requirements: {1 => 1}).requirement_met?(1)).to eq(true)
  end


  it "Get total requirements gained for a member" do
    data = Osm::Badge::Data.new(
      badge: Osm::Badge.new(
        requirements: [
          Osm::Badge::Requirement.new(id: 1),
          Osm::Badge::Requirement.new(id: 2),
          Osm::Badge::Requirement.new(id: 3),
          Osm::Badge::Requirement.new(id: 4),
          Osm::Badge::Requirement.new(id: 5),
          Osm::Badge::Requirement.new(id: 6),
          Osm::Badge::Requirement.new(id: 7),
          Osm::Badge::Requirement.new(id: 8),
          Osm::Badge::Requirement.new(id: 9),
        ]
      ),
      requirements: {
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
    expect(data.total_gained).to eq(4)
  end

  it "Get total requirements met in each module for a member" do
    badge = Osm::Badge.new(
      needed_from_section: {'a' => 1, 'b' => 2},
      requirements: [
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'a', id: 100), id: 1),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'a', id: 100), id: 2),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'b', id: 200), id: 3),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'b', id: 200), id: 4),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'c', id: 300), id: 5),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'c', id: 300), id: 6),
      ],
      modules: [
        Osm::Badge::RequirementModule.new(letter: 'a', id: 100),
        Osm::Badge::RequirementModule.new(letter: 'b', id: 200),
        Osm::Badge::RequirementModule.new(letter: 'c', id: 300),
      ]
    )
    data = Osm::Badge::Data.new(
      badge: badge,
      requirements: { 1=>'x', 2=>'', 3=>'yes', 4=>'2000-01-02', 5=>1 }
    )
    expect(data.gained_in_modules).to eq({'a'=>0, 'b'=>2, 'c'=>1, 100=>0, 200=>2, 300=>1})
  end

  it "Get modules met for a member" do
    badge = Osm::Badge.new(
      requirements: [
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'a', id: 1000), id: 1),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'a', id: 1000), id: 2),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'b', id: 2000), id: 3),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'b', id: 2000), id: 4),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'c', id: 3000), id: 5),
      ],
      modules: [
        Osm::Badge::RequirementModule.new(letter: 'a', id: 1000, min_required: 1 ),
        Osm::Badge::RequirementModule.new(letter: 'b', id: 2000, min_required: 2 ),
        Osm::Badge::RequirementModule.new(letter: 'c', id: 3000, min_required: 1 )
      ]
    )
    data = Osm::Badge::Data.new(
      badge: badge,
      requirements: {1=>'x', 2=>'', 3=>'yes', 4=>'2000-01-02', 5=>'yes'}
    )
    expect(data.modules_gained).to eq(['b', 'c'])
  end

  describe "Works out if the badge has been earnt" do
    it "Staged" do
      badge = Osm::StagedBadge.new(levels: [0, 1, 2, 3])
      data = Osm::Badge::Data.new(awarded: 2, badge: badge)

      allow(data).to receive(:earnt) { 1 }
      expect(data.earnt?).to eq(false)

      allow(data).to receive(:earnt) { 2 }
      expect(data.earnt?).to eq(false)

      allow(data).to receive(:earnt) { 3 }
      expect(data.earnt?).to eq(true)
    end

    it "Non staged" do
      badge = Osm::ActivityBadge.new(
        min_modules_required: 0,
        min_requirements_required: 0,
        modules: [
          Osm::Badge::RequirementModule.new(id: 1, letter: 'a', min_required: 2),
          Osm::Badge::RequirementModule.new(id: 2, letter: 'b', min_required: 1),
          Osm::Badge::RequirementModule.new(id: 3, letter: 'c', min_required: 1),
        ],
        badges_required: [],
        other_requirements_required: [],
        requirements: [
          Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'a', id: 1), id: 10),
          Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'a', id: 1), id: 11),
          Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'b', id: 2), id: 20),
          Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'b', id: 2), id: 21),
          Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'c', id: 3), id: 30),
          Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'c', id: 3), id: 31),
        ],
      )

      data = Osm::Badge::Data.new(due: 1, awarded: 1, badge: badge)
      expect(data.earnt?).to eq(false)

      data = Osm::Badge::Data.new(due: 1, awarded: 0, badge: badge)
      expect(data.earnt?).to eq(true)


      # Number of modules required
      this_badge = badge.clone
      this_badge.min_modules_required = 2

      data = Osm::Badge::Data.new(requirements: {10=>'y', 11=>'y', 20=>'y'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(true)

      data = Osm::Badge::Data.new(requirements: {10=>'y', 11=>'y', 20=>'x'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(false)


      # Number of requirements needed
      this_badge = badge.clone
      this_badge.min_modules_required = 0
      this_badge.min_requirements_required = 2

      data = Osm::Badge::Data.new(requirements: {10=>'y', 11=>'y', 20=>'y'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(true)

      data = Osm::Badge::Data.new(requirements: {10=>'y', 11=>'x', 20=>'y'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(true)

      data = Osm::Badge::Data.new(requirements: {10=>'y', 11=>'x', 20=>'x'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(false)


      # Module combinations
      this_badge = badge.clone
      this_badge.requires_modules = [['a'], ['b', 'c']]

      data = Osm::Badge::Data.new(requirements: {10=>'x', 11=>'x', 20=>'x', 30=>'x'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(false)

      data = Osm::Badge::Data.new(requirements: {10=>'y', 11=>'y', 20=>'x', 30=>'x'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(false)

      data = Osm::Badge::Data.new(requirements: {10=>'y', 11=>'y', 20=>'y', 30=>'x'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(true)

      data = Osm::Badge::Data.new(requirements: {10=>'y', 11=>'y', 20=>'x', 30=>'y'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(true)

      # Requirements from another badge
      this_badge = badge.clone
      this_badge.min_modules_required = 0
      this_badge.min_requirements_required = 1
      this_badge.requires_modules = nil
      # Simply met
      this_badge.other_requirements_required = [{id: 100, min: 0}]
      data = Osm::Badge::Data.new(requirements: {10=>'y'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(true) # Assume met if not in requirements Hash
      data = Osm::Badge::Data.new(requirements: {10=>'y', 100=>'x'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(false)
      data = Osm::Badge::Data.new(requirements: {10=>'y', 100=>'y'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(true)
      # Minimum value
      this_badge.other_requirements_required = [{id: 100, min: 2}]
      data = Osm::Badge::Data.new(requirements: {10=>'y'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(true) # Assume met if not in requirements Hash
      data = Osm::Badge::Data.new(requirements: {10=>'y', 100=>'x'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(false)
      data = Osm::Badge::Data.new(requirements: {10=>'y', 100=>'1'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(false)
      data = Osm::Badge::Data.new(requirements: {10=>'y', 100=>'2'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(true)
      data = Osm::Badge::Data.new(requirements: {10=>'y', 100=>'3'}, due: 0, awarded: 0, badge: this_badge)
      expect(data.earnt?).to eq(true)
    end
  end

  describe "Works out what level of a badge has been earnt" do

    it "Staged (activity)" do
      badge = Osm::StagedBadge.new(
        levels: [0, 1, 2, 3],
        min_modules_required: 0,
        min_requirements_completed: 0,
        modules: [
          Osm::Badge::RequirementModule.new(id: 1, letter: 'a', min_required: 1),
          Osm::Badge::RequirementModule.new(id: 2, letter: 'b', min_required: 1),
          Osm::Badge::RequirementModule.new(id: 3, letter: 'c', min_required: 1),
        ],
        show_level_letters: true,
      )
      badge.requirements = [
        Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'a', id: 1), id: 10),
        Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'a', id: 1), id: 11),
        Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'b', id: 2), id: 20),
        Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'b', id: 2), id: 21),
        Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'c', id: 3), id: 30),
        Osm::Badge::Requirement.new(badge: badge, mod: Osm::Badge::RequirementModule.new(letter: 'c', id: 3), id: 31),
      ]

      requirements = {10=>'',11=>'',20=>'',21=>'',30=>'',31=>''}
      data = Osm::Badge::Data.new(requirements: requirements, badge: badge)
      expect(data.earnt).to eq(0)

      requirements = {10=>'y',11=>'',20=>'',21=>'',30=>'',31=>''}
      data = Osm::Badge::Data.new(requirements: requirements, badge: badge)
      expect(data.earnt).to eq(1)

      requirements = {10=>'y',11=>'',20=>'',21=>'y',30=>'',31=>''}
      data = Osm::Badge::Data.new(requirements: requirements, badge: badge)
      expect(data.earnt).to eq(2)

      requirements = {10=>'',11=>'',20=>'',21=>'y',30=>'',31=>''}
      data = Osm::Badge::Data.new(requirements: requirements, badge: badge)
      expect(data.earnt).to eq(2)

      requirements = {10=>'y',11=>'',20=>'y',21=>'',30=>'y',31=>''}
      data = Osm::Badge::Data.new(requirements: requirements, badge: badge)
      expect(data.earnt).to eq(3)
    end

    it "Staged (count)" do
      badge = Osm::StagedBadge.new(
        levels: [0,1,2,3,4,5,10,15,20],
        show_level_letters: false,
        level_requirement: 3000,
        requirements: []
      )

      expect(Osm::Badge::Data.new(requirements: {3000 => 9},   badge: badge).earnt).to eq(5)
      expect(Osm::Badge::Data.new(requirements: {3000 => 10},  badge: badge).earnt).to eq(10)
      expect(Osm::Badge::Data.new(requirements: {3000 => 11},  badge: badge).earnt).to eq(10)
      expect(Osm::Badge::Data.new(requirements: {3000 => 999}, badge: badge).earnt).to eq(20)
    end

    it "Non staged" do
      data = Osm::Badge::Data.new(badge: Osm::ActivityBadge.new)

      allow(data).to receive(:earnt?) { true }
      expect(data.earnt).to eq(1)

      allow(data).to receive(:earnt?) { false }
      expect(data.earnt).to eq(0)
    end
  end

  it "Works out if the badge has been started" do
    expect(Osm::Badge::Data.new(badge: Osm::CoreBadge.new, requirements: {1 => 'Yes', 2 => ''}).started?).to eq(true)
    expect(Osm::Badge::Data.new(badge: Osm::CoreBadge.new, requirements: {1 => 'Yes', 2 => ''}, due: 1).started?).to eq(false)
    expect(Osm::Badge::Data.new(badge: Osm::CoreBadge.new, requirements: {1 => 'xNo', 2 => ''}).started?).to eq(false)
    expect(Osm::Badge::Data.new(badge: Osm::CoreBadge.new, requirements: {1 => '', 2 => ''}).started?).to eq(false)

    # Staged Activity Badge
    expect(Osm::Badge::Data.new(
      badge: Osm::StagedBadge.new(
        levels: [0,1,2],
        show_level_letters: true,
        requirements: [
          Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'a'), id: 1000),
          Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'b'), id: 2000),
          Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'b'), id: 2001),
        ]
      ),
      requirements: {1000 => 'Yes', 2000 => 'Yes', 2001 => ''},
      due: 1,
    ).started?).to eq(true)

    # Staged Count Badge
    expect(Osm::Badge::Data.new(
      badge: Osm::StagedBadge.new(levels: [0,1,2,3,4,5,10,15,20], show_level_letters: false, level_requirement: 1000),
      requirements: {1000 => 5, 2000 => '5', 3000 => ''},
      due: 5,
      awarded: 4,
    ).started?).to eq(false) # Finished lvl 5 & not started lvl 10
    expect(Osm::Badge::Data.new(
      badge: Osm::StagedBadge.new(levels: [0,1,2,3,4,5,10,15,20], show_level_letters: false, level_requirement: 1000),
      requirements: {1000 => 6, 2000 => '6', 3000 => ''},
      due: 5,
      awarded: 3,
    ).started?).to eq(true) # Finished lvl 5 & started lvl 10
  end

  it "Works out what stage of the badge has been started" do
    # Non-Staged badges (0 or 1)
    expect(Osm::Badge::Data.new(badge: Osm::CoreBadge.new, requirements: {10 => 'Yes', 11 => ''}).started).to eq(1)
    expect(Osm::Badge::Data.new(badge: Osm::CoreBadge.new, requirements: {10 => 'Yes', 11 => ''}, due: 1).started).to eq(0)
    expect(Osm::Badge::Data.new(badge: Osm::CoreBadge.new, requirements: {10 => 'xNo', 11 => ''}).started).to eq(0)
    expect(Osm::Badge::Data.new(badge: Osm::CoreBadge.new, requirements: {10 => '', 11 => ''}).started).to eq(0)


    # Staged Activity
    staged_activity = Osm::StagedBadge.new(
      levels: [0,1,2],
      show_level_letters: true,
      requirements: [
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'a'), id: 100),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'b'), id: 200),
        Osm::Badge::Requirement.new(mod: Osm::Badge::RequirementModule.new(letter: 'b'), id: 201),
      ]
    )

    expect(Osm::Badge::Data.new(
      badge: staged_activity,
      requirements: {100 => 'Yes', 200 => 'Yes', 201 => ''},
      due: 1,
    ).started).to eq(2)
    expect(Osm::Badge::Data.new(
      badge: staged_activity,
      requirements: {100 => 'Yes', 200 => 'Yes', 201 => ''},
      due: 1,
    ).started).to eq(2)
    expect(Osm::Badge::Data.new(
      badge: staged_activity,
      requirements: {},
      due: 2,
    ).started).to eq(0) # No more stages to do


    # Staged count
    staged_count = Osm::StagedBadge.new(
      levels: [0,1,2,3,4,5,10,15,20],
      show_level_letters: false,
      level_requirement: 3000,
      requirements: []
    )

    expect(Osm::Badge::Data.new(
      badge: staged_count,
      requirements: {3000 => 7},
      due: 5,
    ).started).to eq(10)
    expect(Osm::Badge::Data.new(
      badge: staged_count,
      requirements: {3000 => 3},
      due: 3,
    ).started).to eq(0)
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
      end

      urls = {
        Osm::CoreBadge =>      'ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=4&term_id=2&section_id=1',
        Osm::ChallengeBadge => 'ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=1&term_id=2&section_id=1',
        Osm::StagedBadge =>    'ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=3&term_id=2&section_id=1',
        Osm::ActivityBadge =>  'ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=2&term_id=2&section_id=1',
      }
      urls.each do |type, path|
        it type.type.to_s.titleize do
          expect($api).to receive(:post_query).with(path).and_return(@badge_data)
          expect($api).to receive(:post_query).with('ext/badges/records/?action=_getModuleDetails').and_return(@module_data)
          allow(Osm::Term).to receive(:get_current_term_for_section){ Osm::Term.new(id: 2) }

          badges = type.get_badges_for_section(api: $api, section: Osm::Section.new(id: 1, type: :beavers))
          expect(badges.size).to eq(1)
          badge = badges[0]
          expect(badge.name).to eq('b_name')
          expect(badge.requirement_notes).to eq('b_req_notes')
          expect(badge.identifier).to eq('123_0')
          expect(badge.id).to eq(123)
          expect(badge.version).to eq(0)
          expect(badge.latest).to eq(true)
          expect(badge.user_id).to eq(0)
          expect(badge.sharing).to eq(:default_locked)
          expect(badge.requirements.size).to eq(1)
          expect(badge.min_modules_required).to eq(1)
          expect(badge.min_requirements_required).to eq(0)
          expect(badge.add_columns_to_module).to eq(nil)
          expect(badge.level_requirement).to eq(nil)
          expect(badge.requires_modules).to eq(nil)
          expect(badge.other_requirements_required).to eq([])
          expect(badge.badges_required).to eq([])
          expect(badge.show_level_letters).to eq(true)
          expect(badge.valid?).to eq(true)
          expect(badge.modules.size).to eq(1)
          m = badge.modules[0]
          expect(m.badge.id).to eq(123)
          expect(m.badge.version).to eq(0)
          expect(m.id).to eq(234)
          expect(m.letter).to eq('a')
          expect(m.min_required).to eq(0)
          expect(m.custom_columns).to eq(0)
          expect(m.completed_into_column).to eq(nil)
          expect(m.numeric_into_column).to eq(nil)
          expect(m.add_column_id_to_numeric).to eq(nil)
          expect(m.valid?).to eq(true)
          requirement = badge.requirements[0]
          expect(requirement.name).to eq('r_name')
          expect(requirement.description).to eq('r_description')
          expect(requirement.id).to eq(2345)
          expect(requirement.mod).to eq(m)
          expect(requirement.editable).to eq(true)
          expect(requirement.badge).to eq(badge)
          expect(requirement.valid?).to eq(true)
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

      expect($api).to receive(:post_query).with("ext/badges/records/?action=getBadgeRecords&term_id=2&section=beavers&badge_id=123&section_id=1&badge_version=0").and_return(data)
      datas = Osm::CoreBadge.new(id: 123, version: 0).get_data_for_section(api: $api, section: Osm::Section.new(id: 1, type: :beavers), term: 2)
      expect(datas.size).to eq(1)
      data = datas[0]
      expect(data.member_id).to eq(3)
      expect(data.first_name).to eq('fn')
      expect(data.last_name).to eq('ln')
      expect(data.due).to eq(2)
      expect(data.awarded).to eq(1)
      expect(data.awarded_date).to eq(Date.new(2000, 1, 2))
      expect(data.requirements).to eq({2345 => 'd'})
      expect(data.section_id).to eq(1)
      expect(data.badge.id).to eq(123)
    end

    describe "Update badge data in OSM" do

      before :each do
        @update_post_data = {
          'scoutid' => 1,
          'section_id' => 2,
          'badge_id' => 123,
          'badge_version' => 0,
          'field' => 2345,
          'value' => '2'
        }
        @update_body_data = {'scoutid' => '1', '2345' => '2', 'completed' => '0', 'awarded' => '0', 'firstname' => 'fn', 'lastname' => 'ln'}

        @data = Osm::Badge::Data.new(
          member_id: 1,
          first_name: 'fn',
          last_name: 'ln',
          section_id: 2,
          requirements: {2345 => '1', 6789 => '2'},
          badge: Osm::CoreBadge.new(
            id: 123,
            version: 0,
            requirements: [
              Osm::Badge::Requirement.new(id: 2345, editable: true),
              Osm::Badge::Requirement.new(id: 6789, editable: true),
            ]),
          due: 0,
        )
     end

     it "Success (requirmeent, due & awarded)" do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).to receive(:mark_awarded).with($api, date, 1) { true }
        expect(@data).to receive(:mark_due).with($api, 1) { true }
        expect($api).to receive(:post_query).with("ext/badges/records/?action=updateSingleRecord", post_data: @update_post_data).and_return(@update_body_data)

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        expect(@data.update($api)).to eq(true)
      end

      it "Success (just requirement)" do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).not_to receive(:mark_awarded)
        expect(@data).not_to receive(:mark_due)
        expect($api).to receive(:post_query).with("ext/badges/records/?action=updateSingleRecord", post_data: @update_post_data).and_return(@update_body_data)

        @data.requirements[2345] = '2'
        expect(@data.update($api)).to eq(true)
      end

      it "Success (just requirement) (to blank)" do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).not_to receive(:mark_awarded)
        expect(@data).not_to receive(:mark_due)
        expect($api).to receive(:post_query).with("ext/badges/records/?action=updateSingleRecord", post_data: @update_post_data.merge('value' => '')).and_return(@update_body_data.merge('2345' => ''))

        @data.requirements[2345] = ''
        expect(@data.update($api)).to eq(true)
      end

      it "Success (just due)" do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).not_to receive(:mark_awarded)
        expect(@data).to receive(:mark_due).with($api, 1) { true }
        expect($api).not_to receive(:post_query)

        @data.due = 1
        expect(@data.update($api)).to eq(true)
      end

      it "Success (just awarded)" do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).to receive(:mark_awarded).with($api, date, 1) { true }
        expect(@data).not_to receive(:mark_due).with($api, 1) { true }
        expect($api).not_to receive(:post_query)

        @data.awarded = 1
        @data.awarded_date = date
        expect(@data.update($api)).to eq(true)
      end

      it "Failed (requirement)" do
        date = Date.new(2000, 1, 2)
        @update_body_data['2345'] = '1'
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).to receive(:mark_awarded).with($api, date, 1) { true }
        expect(@data).to receive(:mark_due).with($api, 1) { true }
        expect($api).to receive(:post_query).with("ext/badges/records/?action=updateSingleRecord", post_data: @update_post_data).and_return(@update_body)

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        expect(@data.update($api)).to eq(false)
      end

      it "Failed (due)" do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).to receive(:mark_awarded).with($api, date, 1) { true }
        expect(@data).to receive(:mark_due).with($api, 1) { false }
        expect($api).to receive(:post_query).with("ext/badges/records/?action=updateSingleRecord", post_data: @update_post_data).and_return(@update_body)

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        expect(@data.update($api)).to eq(false)
      end

      it "Failed (awarded)" do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).to receive(:mark_awarded).with($api, date, 1) { false }
        expect(@data).to receive(:mark_due).with($api, 1) { true }
        expect($api).to receive(:post_query).with("ext/badges/records/?action=updateSingleRecord", post_data: @update_post_data).and_return(@update_body)

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        expect(@data.update($api)).to eq(false)
      end

    end


    it "Mark badge awarded" do

      awarded_post_data = {
        'date' => '2000-01-02',
        'sectionid' => 2,
        'entries' => '[{"badge_id":"123","badge_version":"0","scout_id":"1","level":"1"}]',
      }
      awarded_body_data = {'scoutid'=>'1', 'completed'=>'1', 'awarded' => '1', 'awardeddate'=>'2000-01-02', 'firstname' => 'fn', 'lastname' => 'ln'}

      data = Osm::Badge::Data.new(
        member_id: 1,
        section_id: 2,
        badge: Osm::CoreBadge.new(
          id: 123,
          version: 0
        )
      )

      expect($api).to receive(:post_query).with('ext/badges/records/?action=awardBadge', post_data: awarded_post_data).and_return(awarded_body_data)
      allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }

      expect(data.mark_awarded(api: $api, date: Date.new(2000, 1, 2), level: 1)).to eq(true)
    end

    it "Mark badge due" do

      awarded_post_data = {
        'section_id' => 2,
        'badge_id' => 123,
        'badge_version' => 0,
        'scoutid' => 1,
        'level' => 1
      }
      awarded_body_data = {'scoutid'=>'1', 'completed'=>'1', 'awarded' => '1', 'awardeddate'=>'2000-01-02', 'firstname' => 'fn', 'lastname' => 'ln'}

      data = Osm::Badge::Data.new(
        member_id: 1,
        section_id: 2,
        badge: Osm::CoreBadge.new(
          id: 123,
          version: 0
        )
      )

      expect($api).to receive(:post_query).twice.with('ext/badges/records/?action=overrideCompletion', post_data: awarded_post_data).and_return(awarded_body_data)
      allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
      allow(data).to receive(:earnt){ 1 }

      expect(data.mark_due($api, 1)).to eq(true)
      expect(data.mark_due($api)).to eq(true)
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
      data = data

      expect($api).to receive(:post_query).with("ext/badges/records/summary/?action=get&mode=verbose&section=beavers&sectionid=1&termid=2").and_return(data)
      summary = Osm::Badge.get_summary_for_section(api: $api, section: Osm::Section.new(id: 1, type: :beavers), term: 2)
      expect(summary.size).to eq(1)
      expect(summary[0]).to eq({
        first_name: 'First',
        last_name: 'Last',
        name: 'First Last',
        member_id: 1,
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
      })
    end

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
      expect($api).to receive(:post_query).with('ext/badges/due/?action=get&section=cubs&sectionid=1&termid=2').and_return(data)

      db = Osm::Badge.get_due_badges(api: $api, section: Osm::Section.new(id: 1, type: :cubs), term: 2)
      expect(db.empty?).to eq(false)
      expect(db.badge_names).to eq({'145_0_1'=>'Activity - Badge Name', '93_0_2'=>'Staged - Participation (Lvl 2)'})
      expect(db.by_member).to eq({1=>['93_0_2', '145_0_1'], 2=>['93_0_2']})
      expect(db.member_names).to eq({1 => 'John Doe', 2 => 'Jane Doe'})
      expect(db.badge_stock).to eq({'93_0_2'=>20, '145_0_1'=>10})
      expect(db.totals).to eq({'93_0_2'=>2, '145_0_1'=>1})
      expect(db.valid?).to eq(true)
    end

    it "handles an empty array representing no due badges" do
      expect($api).to receive(:post_query).with('ext/badges/due/?action=get&section=cubs&sectionid=1&termid=2').and_return([])
      db = Osm::Badge.get_due_badges(api: $api, section: Osm::Section.new(id: 1, type: :cubs), term: 2)
      expect(db).not_to be_nil
    end


    it "Fetch badge stock levels" do
      badges_body = {
        'identifier' => 'badge_id_level',
        'items' => [
          { 'shortname' => 'badge_1', 'stock' => 1, 'desired' => 0, 'due' => 0, 'badge_id_level' => '100_1' },
          { 'shortname' => 'badge_2', 'stock' => 2, 'desired' => 0, 'due' => 0, 'badge_id_level' => '200_2' },
        ]
      }
      expect($api).to receive(:post_query).with('ext/badges/stock/?action=getBadgeStock&section=beavers&section_id=1&term_id=2').and_return(badges_body)
      allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 2) }

      section = Osm::Section.new(id: 1, type: :beavers)
      expect(Osm::Badge.get_stock(api: $api, section: section)).to eq({'100_1' => 1, '200_2' => 2})
    end

    describe "Update badge stock levels" do

      before :each do
        @path = "ext/badges.php?action=updateStock"
        @post_body = {
          'stock' => 10,
          'sectionid' => 2,
          'section' => :beavers,
          'type' => 'current',
          'level' => 1,
          'badge_id' => 3
        }
        @section = Osm::Section.new(id: 2, type: :beavers)
      end

      it "Succeds" do
        expect($api).to receive(:post_query).with(@path, post_data: @post_body).and_return({'ok' => true})
        expect(Osm::Badge.update_stock(api: $api, section: @section, badge_id: 3, stock: 10)).to eq(true)
      end

      it "Fails" do
        expect($api).to receive(:post_query).with(@path, post_data: @post_body).and_return({'ok' => false})
        expect(Osm::Badge.update_stock(api: $api, section: @section, badge_id: 3, stock: 10)).to eq(false)
      end

    end # describe - Update badge stock levels

  end # describe using the OSM API

end
