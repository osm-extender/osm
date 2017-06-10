describe Osm::Badge do

  describe 'Create' do

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
        show_level_letters: true
      }
    end

    it 'Attributes set' do
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

    it 'Valid with nil for levels' do
      badge = Osm::Badge.new(@badge_options.merge(levels: nil))
      expect(badge.levels).to be_nil
      expect(badge.valid?).to eq(true)
    end

    it 'Valid with nil for level_requirement' do
      badge = Osm::Badge.new(@badge_options.merge(level_requirement: nil))
      expect(badge.level_requirement).to be_nil
      expect(badge.valid?).to eq(true)
    end
    
    it 'Valid with nil for add_columns_to_module' do
      badge = Osm::Badge.new(@badge_options.merge(add_columns_to_module: nil))
      expect(badge.add_columns_to_module).to be_nil
      expect(badge.valid?).to eq(true)
    end

  end


  it 'Works out if we add columns to this badge' do
    expect(Osm::Badge.new(add_columns_to_module: 123).add_columns?).to eq(true)
    expect(Osm::Badge.new(add_columns_to_module: nil).add_columns?).to eq(false)
  end

  it 'Produces a map of module letter <-> module id' do
    badge = Osm::Badge.new(modules: [
      Osm::Badge::RequirementModule.new(id: 2, letter: 'c'),
      Osm::Badge::RequirementModule.new(id: 10, letter: 'b'),
      Osm::Badge::RequirementModule.new(id: 1, letter: 'a')
    ])

    expect(badge.module_map).to eq(1 => 'a', 10 => 'b', 2 => 'c', 'a' => 1, 'b' => 10, 'c' => 2)
  end

  it 'Gets the number of requirements needed per module' do
    badge = Osm::Badge.new(modules: [
      Osm::Badge::RequirementModule.new(id: 2, letter: 'c', min_required: 5),
      Osm::Badge::RequirementModule.new(id: 10, letter: 'b', min_required: 4),
      Osm::Badge::RequirementModule.new(id: 1, letter: 'a', min_required: 3)
    ])

    expect(badge.needed_per_module).to eq('a' => 3, 'b' => 4, 'c' => 5, 2 => 5, 10 => 4, 1 => 3)
  end

  it 'Produces a list of modules' do
    badge = Osm::Badge.new(modules: [
      Osm::Badge::RequirementModule.new(id: 2, letter: 'c'),
      Osm::Badge::RequirementModule.new(id: 10, letter: 'b'),
      Osm::Badge::RequirementModule.new(id: 1, letter: 'a')
    ])

    expect(badge.module_letters).to eq(['a', 'b', 'c'])
    expect(badge.module_ids).to eq([1, 2, 10])
  end


  it 'Compare by name then id then version (descending)' do
    b1 = Osm::Badge.new(name: 'A', id: 1, version: 1)
    b2 = Osm::Badge.new(name: 'B', id: 1, version: 1)
    b3 = Osm::Badge.new(name: 'B', id: 2, version: 2)
    b4 = Osm::Badge.new(name: 'B', id: 2, version: 1)
    badges = [b3, b1, b4, b2]
    expect(badges.sort).to eq([b1, b2, b3, b4])
  end


  describe 'Using the OSM API' do

    describe 'Get Badges' do

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
              'userid' => '0'
            }
          },
          'structure' => {
            '123_0' => [
              {
                'rows' => [
                  { 'name' => 'First name','field' => 'firstname','width' => '120px' },
                  { 'name' => 'Last name','field' => 'lastname','width' => '120px' },
                  { 'name' => 'Done','field' => 'completed','width' => '70px','formatter' => 'doneFormatter' },
                  { 'name' => 'Awarded','field' => 'awardeddate','width' => '100px','formatter' => 'dueFormatter' }
                ],
                'numactivities' => '23',
                'noscroll' => true
               },{
                'rows' => [
                  { 'name' => 'r_name','field' => '2345','width' => '80px','formatter' => 'cellFormatter','tooltip' => 'r_description','editable' => 'true','module' => 'a' }
                ]
              }
            ]
          }
        }

        @module_data = { 'items' => [
          {
            'badge_id' => '123',
            'badge_version' => '0',
            'module_id' => '234',
            'module_letter' => 'a',
            'num_required' => '',
            'custom_columns' => '',
            'completed_into_column_id' => '',
            'numeric_into_column_id' => '',
            'add_column_id_to_numeric' => ''
          }
        ] }
      end

      urls = {
        Osm::CoreBadge =>      'ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=4&term_id=2&section_id=1',
        Osm::ChallengeBadge => 'ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=1&term_id=2&section_id=1',
        Osm::StagedBadge =>    'ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=3&term_id=2&section_id=1',
        Osm::ActivityBadge =>  'ext/badges/records/?action=getBadgeStructureByType&section=beavers&type_id=2&term_id=2&section_id=1'
      }
      urls.each do |type, path|
        it type.type.to_s.titleize do
          expect($api).to receive(:post_query).with(path).and_return(@badge_data)
          expect($api).to receive(:post_query).with('ext/badges/records/?action=_getModuleDetails').and_return(@module_data)
          allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 2) }

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


    it 'Get badge data for a section' do
      data = {
        'identifier' => 'scoutid',
        'items' => [{
          'scoutid' => '3',
          'firstname' => 'fn',
          'lastname' => 'ln',
          'completed' => '2',
          'awarded' => '1',
          'awardeddate' => '2000-01-02',
          '2345' => 'd'
        }]
      }

      expect($api).to receive(:post_query).with('ext/badges/records/?action=getBadgeRecords&term_id=2&section=beavers&badge_id=123&section_id=1&badge_version=0').and_return(data)
      datas = Osm::CoreBadge.new(id: 123, version: 0).get_data_for_section(api: $api, section: Osm::Section.new(id: 1, type: :beavers), term: 2)
      expect(datas.size).to eq(1)
      data = datas[0]
      expect(data.member_id).to eq(3)
      expect(data.first_name).to eq('fn')
      expect(data.last_name).to eq('ln')
      expect(data.due).to eq(2)
      expect(data.awarded).to eq(1)
      expect(data.awarded_date).to eq(Date.new(2000, 1, 2))
      expect(data.requirements).to eq(2345 => 'd')
      expect(data.section_id).to eq(1)
      expect(data.badge.id).to eq(123)
    end

    it 'Get summary data for a section' do

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
            '98_0' => '02/03/2004 (Lvl 1)'
          }
        ]
      }
      data = data

      expect($api).to receive(:post_query).with('ext/badges/records/summary/?action=get&mode=verbose&section=beavers&sectionid=1&termid=2').and_return(data)
      summary = Osm::Badge.get_summary_for_section(api: $api, section: Osm::Section.new(id: 1, type: :beavers), term: 2)
      expect(summary.size).to eq(1)
      expect(summary[0]).to eq(        first_name: 'First',
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
        '98_0_level' => 1)
    end

    it 'Get due badges' do
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
          }
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
              'type_id' => '3'
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
              'type_id' => '3'
            }
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
            'type_id' => '2'
          }]
        }
      }
      expect($api).to receive(:post_query).with('ext/badges/due/?action=get&section=cubs&sectionid=1&termid=2').and_return(data)

      db = Osm::Badge.get_due_badges(api: $api, section: Osm::Section.new(id: 1, type: :cubs), term: 2)
      expect(db.empty?).to eq(false)
      expect(db.badge_names).to eq('145_0_1' => 'Activity - Badge Name', '93_0_2' => 'Staged - Participation (Lvl 2)')
      expect(db.by_member).to eq(1 => ['93_0_2', '145_0_1'], 2 => ['93_0_2'])
      expect(db.member_names).to eq(1 => 'John Doe', 2 => 'Jane Doe')
      expect(db.badge_stock).to eq('93_0_2' => 20, '145_0_1' => 10)
      expect(db.totals).to eq('93_0_2' => 2, '145_0_1' => 1)
      expect(db.valid?).to eq(true)
    end

    it 'handles an empty array representing no due badges' do
      expect($api).to receive(:post_query).with('ext/badges/due/?action=get&section=cubs&sectionid=1&termid=2').and_return([])
      db = Osm::Badge.get_due_badges(api: $api, section: Osm::Section.new(id: 1, type: :cubs), term: 2)
      expect(db).not_to be_nil
    end


    it 'Fetch badge stock levels' do
      badges_body = {
        'identifier' => 'badge_id_level',
        'items' => [
          { 'shortname' => 'badge_1', 'stock' => 1, 'desired' => 0, 'due' => 0, 'badge_id_level' => '100_1' },
          { 'shortname' => 'badge_2', 'stock' => 2, 'desired' => 0, 'due' => 0, 'badge_id_level' => '200_2' }
        ]
      }
      expect($api).to receive(:post_query).with('ext/badges/stock/?action=getBadgeStock&section=beavers&section_id=1&term_id=2').and_return(badges_body)
      allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 2) }

      section = Osm::Section.new(id: 1, type: :beavers)
      expect(Osm::Badge.get_stock(api: $api, section: section)).to eq('100_1' => 1, '200_2' => 2)
    end

    describe 'Update badge stock levels' do

      before :each do
        @path = 'ext/badges.php?action=updateStock'
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

      it 'Succeds' do
        expect($api).to receive(:post_query).with(@path, post_data: @post_body).and_return('ok' => true)
        expect(Osm::Badge.update_stock(api: $api, section: @section, badge_id: 3, stock: 10)).to eq(true)
      end

      it 'Fails' do
        expect($api).to receive(:post_query).with(@path, post_data: @post_body).and_return('ok' => false)
        expect(Osm::Badge.update_stock(api: $api, section: @section, badge_id: 3, stock: 10)).to eq(false)
      end

    end # describe - Update badge stock levels

  end # describe using the OSM API

end
