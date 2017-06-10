describe Osm::Badge::Data do

  it 'Create' do
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

  it 'Compare by badge, section_id then member_id' do
    b1 = Osm::Badge::Data.new(badge: Osm::Badge.new(name: 'A'), section_id: 1, member_id: 1)
    b2 = Osm::Badge::Data.new(badge: Osm::Badge.new(name: 'B'), section_id: 1, member_id: 1)
    b3 = Osm::Badge::Data.new(badge: Osm::Badge.new(name: 'B'), section_id: 2, member_id: 1)
    b4 = Osm::Badge::Data.new(badge: Osm::Badge.new(name: 'B'), section_id: 2, member_id: 2)
    badges = [b3, b4, b1, b2]
    expect(badges.sort).to eq([b1, b2, b3, b4])
  end

  it 'Works out if a requirement has been met' do
    data = expect(Osm::Badge::Data.new(requirements: {1 => ''}).requirement_met?(1)).to eq(false)
    data = expect(Osm::Badge::Data.new(requirements: {1 => 'xStuff'}).requirement_met?(1)).to eq(false)
    data = expect(Osm::Badge::Data.new(requirements: {1 => '0'}).requirement_met?(1)).to eq(false)
    data = expect(Osm::Badge::Data.new(requirements: {1 => 0}).requirement_met?(1)).to eq(false)
    data = expect(Osm::Badge::Data.new(requirements: {}).requirement_met?(1)).to eq(false)
    data = expect(Osm::Badge::Data.new(requirements: {1 => 'Stuff'}).requirement_met?(1)).to eq(true)
    data = expect(Osm::Badge::Data.new(requirements: {1 => '1'}).requirement_met?(1)).to eq(true)
    data = expect(Osm::Badge::Data.new(requirements: {1 => 1}).requirement_met?(1)).to eq(true)
  end


  it 'Get total requirements gained for a member' do
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

  it 'Get total requirements met in each module for a member' do
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

  it 'Get modules met for a member' do
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

  describe 'Works out if the badge has been earnt' do
    it 'Staged' do
      badge = Osm::StagedBadge.new(levels: [0, 1, 2, 3])
      data = Osm::Badge::Data.new(awarded: 2, badge: badge)

      allow(data).to receive(:earnt) { 1 }
      expect(data.earnt?).to eq(false)

      allow(data).to receive(:earnt) { 2 }
      expect(data.earnt?).to eq(false)

      allow(data).to receive(:earnt) { 3 }
      expect(data.earnt?).to eq(true)
    end

    it 'Non staged' do
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

  describe 'Works out what level of a badge has been earnt' do

    it 'Staged (activity)' do
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

    it 'Staged (count)' do
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

    it 'Non staged' do
      data = Osm::Badge::Data.new(badge: Osm::ActivityBadge.new)

      allow(data).to receive(:earnt?) { true }
      expect(data.earnt).to eq(1)

      allow(data).to receive(:earnt?) { false }
      expect(data.earnt).to eq(0)
    end
  end

  it 'Works out if the badge has been started' do
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

  it 'Works out what stage of the badge has been started' do
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
      requirements: {100 => 'Yes', 200 => 'Yes', 201 => 'Yes'},
      due: 2,
    ).started).to eq(0) # No more stages to do
    expect(Osm::Badge::Data.new(
      badge: staged_activity,
      requirements: {},
      due: 0,
    ).started).to eq(0) # No stages started


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


  describe 'Using the OSM API' do

    describe 'Update badge data in OSM' do

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

     it 'Success (requirmeent, due & awarded)' do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).to receive(:mark_awarded).with($api, date, 1) { true }
        expect(@data).to receive(:mark_due).with($api, 1) { true }
        expect($api).to receive(:post_query).with('ext/badges/records/?action=updateSingleRecord', post_data: @update_post_data).and_return(@update_body_data)

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        expect(@data.update($api)).to eq(true)
      end

      it 'Success (just requirement)' do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).not_to receive(:mark_awarded)
        expect(@data).not_to receive(:mark_due)
        expect($api).to receive(:post_query).with('ext/badges/records/?action=updateSingleRecord', post_data: @update_post_data).and_return(@update_body_data)

        @data.requirements[2345] = '2'
        expect(@data.update($api)).to eq(true)
      end

      it 'Success (just requirement) (to blank)' do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).not_to receive(:mark_awarded)
        expect(@data).not_to receive(:mark_due)
        expect($api).to receive(:post_query).with('ext/badges/records/?action=updateSingleRecord', post_data: @update_post_data.merge('value' => '')).and_return(@update_body_data.merge('2345' => ''))

        @data.requirements[2345] = ''
        expect(@data.update($api)).to eq(true)
      end

      it 'Success (just due)' do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).not_to receive(:mark_awarded)
        expect(@data).to receive(:mark_due).with($api, 1) { true }
        expect($api).not_to receive(:post_query)

        @data.due = 1
        expect(@data.update($api)).to eq(true)
      end

      it 'Success (just awarded)' do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).to receive(:mark_awarded).with($api, date, 1) { true }
        expect(@data).not_to receive(:mark_due).with($api, 1) { true }
        expect($api).not_to receive(:post_query)

        @data.awarded = 1
        @data.awarded_date = date
        expect(@data.update($api)).to eq(true)
      end

      it 'Failed (requirement)' do
        date = Date.new(2000, 1, 2)
        @update_body_data['2345'] = '1'
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).to receive(:mark_awarded).with($api, date, 1) { true }
        expect(@data).to receive(:mark_due).with($api, 1) { true }
        expect($api).to receive(:post_query).with('ext/badges/records/?action=updateSingleRecord', post_data: @update_post_data).and_return(@update_body)

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        expect(@data.update($api)).to eq(false)
      end

      it 'Failed (due)' do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).to receive(:mark_awarded).with($api, date, 1) { true }
        expect(@data).to receive(:mark_due).with($api, 1) { false }
        expect($api).to receive(:post_query).with('ext/badges/records/?action=updateSingleRecord', post_data: @update_post_data).and_return(@update_body)

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        expect(@data.update($api)).to eq(false)
      end

      it 'Failed (awarded)' do
        date = Date.new(2000, 1, 2)
        allow(Osm::Section).to receive(:get) { Osm::Section.new(id: 2, type: :beavers) }
        expect(@data).to receive(:mark_awarded).with($api, date, 1) { false }
        expect(@data).to receive(:mark_due).with($api, 1) { true }
        expect($api).to receive(:post_query).with('ext/badges/records/?action=updateSingleRecord', post_data: @update_post_data).and_return(@update_body)

        @data.requirements[2345] = '2'
        @data.due = 1
        @data.awarded = 1
        @data.awarded_date = date
        expect(@data.update($api)).to eq(false)
      end

    end # describe update badges in OSM


    it 'Mark badge awarded' do

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

    it 'Mark badge due' do

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

  end # describe Using the OSM API

end
