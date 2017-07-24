describe OSM::Term do

  before :each do
    @attributes = {
      id: 1,
      section_id: 2,
      name: 'Term name',
      start: Date.new(2001, 01, 01),
      finish: Date.new(2001, 03, 31)
    }
  end

  it 'Create' do
    term = OSM::Term.new(@attributes)

    expect(term.id).to eq(1)
    expect(term.section_id).to eq(2)
    expect(term.name).to eq('Term name')
    expect(term.start).to eq(Date.new(2001, 1, 1))
    expect(term.finish).to eq(Date.new(2001, 3, 31))
    expect(term.valid?).to eq(true)
  end

  it 'Compares two matching terms' do
    term1 = OSM::Term.new(@attributes)
    term2 = OSM::Term.new(@attributes)
    expect(term1).to eq(term2)
  end

  it 'Compares two non-matching terms' do
    term = OSM::Term.new(@attributes)

    expect(term).not_to eq(OSM::Term.new(@attributes.merge(id: 3)))
  end

  it 'Sorts by Section ID, Start date and then Term ID' do
    term1 = OSM::Term.new(@attributes.merge(section_id: 1, term: 11, start: (Date.today - 60), finish: (Date.today - 1)))
    term2 = OSM::Term.new(@attributes.merge(section_id: 1, term: 12, start: (Date.today -  0), finish: (Date.today + 0)))
    term3 = OSM::Term.new(@attributes.merge(section_id: 1, term: 13, start: (Date.today +  1), finish: (Date.today + 60)))
    term4 = OSM::Term.new(@attributes.merge(section_id: 2, term: 1, start: (Date.today +  1), finish: (Date.today + 60)))
    term5 = OSM::Term.new(@attributes.merge(section_id: 2, term: 2, start: (Date.today +  1), finish: (Date.today + 60)))

    data = [term5, term3, term2, term4, term1]
    expect(data.sort).to eq([term1, term2, term3, term4, term5])
  end

  it 'Works out if it is completly before a date' do
    term1 = OSM::Term.new(@attributes.merge(start: (Date.today - 60), finish: (Date.today - 1)))
    term2 = OSM::Term.new(@attributes.merge(start: (Date.today -  0), finish: (Date.today + 0)))
    term3 = OSM::Term.new(@attributes.merge(start: (Date.today +  1), finish: (Date.today + 60)))

    expect(term1.before?(Date.today)).to eq(true)
    expect(term2.before?(Date.today)).to eq(false)
    expect(term3.before?(Date.today)).to eq(false)
  end

  it 'Works out if it is completly after a date' do
    term1 = OSM::Term.new(@attributes.merge(start: (Date.today - 60), finish: (Date.today - 1)))
    term2 = OSM::Term.new(@attributes.merge(start: (Date.today -  0), finish: (Date.today + 0)))
    term3 = OSM::Term.new(@attributes.merge(start: (Date.today +  1), finish: (Date.today + 60)))

    expect(term1.after?(Date.today)).to eq(false)
    expect(term2.after?(Date.today)).to eq(false)
    expect(term3.after?(Date.today)).to eq(true)
  end

  it 'Works out if it has passed' do
    term1 = OSM::Term.new(@attributes.merge(start: (Date.today - 60), finish: (Date.today - 1)))
    term2 = OSM::Term.new(@attributes.merge(start: (Date.today -  0), finish: (Date.today + 0)))
    term3 = OSM::Term.new(@attributes.merge(start: (Date.today +  1), finish: (Date.today + 60)))

    expect(term1.past?()).to eq(true)
    expect(term2.past?()).to eq(false)
    expect(term3.past?()).to eq(false)
  end

  it 'Works out if it is in the future' do
    term1 = OSM::Term.new(@attributes.merge(start: (Date.today - 60), finish: (Date.today - 1)))
    term2 = OSM::Term.new(@attributes.merge(start: (Date.today -  0), finish: (Date.today + 0)))
    term3 = OSM::Term.new(@attributes.merge(start: (Date.today +  1), finish: (Date.today + 60)))

    expect(term1.future?()).to eq(false)
    expect(term2.future?()).to eq(false)
    expect(term3.future?()).to eq(true)
  end

  it 'Works out if it is the current term' do
    term1 = OSM::Term.new(@attributes.merge(start: (Date.today - 60), finish: (Date.today - 1)))
    term2 = OSM::Term.new(@attributes.merge(start: (Date.today -  0), finish: (Date.today + 0)))
    term3 = OSM::Term.new(@attributes.merge(start: (Date.today +  1), finish: (Date.today + 60)))

    expect(term1.current?()).to eq(false)
    expect(term2.current?()).to eq(true)
    expect(term3.current?()).to eq(false)
  end

  it 'Works out if it contains a date' do
    term1 = OSM::Term.new(@attributes.merge(start: (Date.today - 60), finish: (Date.today - 1)))
    term2 = OSM::Term.new(@attributes.merge(start: (Date.today -  0), finish: (Date.today + 0)))
    term3 = OSM::Term.new(@attributes.merge(start: (Date.today +  1), finish: (Date.today + 60)))

    expect(term1.contains_date?(Date.today)).to eq(false)
    expect(term2.contains_date?(Date.today)).to eq(true)
    expect(term3.contains_date?(Date.today)).to eq(false)
  end

  it 'Date helpers return false for nil dates' do
    term = OSM::Term.new
    expect(term.before?(Date.today)).to eq(false)
    expect(term.after?(Date.today)).to eq(false)
    expect(term.past?).to eq(false)
    expect(term.future?).to eq(false)
    expect(term.current?).to eq(false)
    expect(term.contains_date?(Date.today)).to eq(false)
  end


  describe 'Using the API' do

    describe 'Get all terms' do
      before :each do
        body = [
          { 'sectionConfig' => '{"subscription_level":1,"subscription_expires":"2013-01-05","sectionType":"beavers","columnNames":{"column_names":"names"},"numscouts":10,"hasUsedBadgeRecords":true,"hasProgramme":true,"extraRecords":[{"name":"Flexi Record 1","extraid":"111"}],"wizard":"false","fields":{"fields":true},"intouch":{"intouch_fields":true},"mobFields":{"mobile_fields":true}}', 'groupname' => '3rd Somewhere', 'groupid' => '3', 'groupNormalised' => '1', 'sectionid' => '9', 'sectionname' => 'Section 1', 'section' => 'beavers', 'isDefault' => '1', 'permissions' => { 'badge' => 10, 'member' => 20, 'user' => 100, 'register' => 100, 'contact' => 100, 'programme' => 100, 'originator' => 1, 'events' => 100, 'finance' => 100, 'flexi' => 100 } },
          { 'sectionConfig' => "{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"cubs\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member's Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member's Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}", 'groupname' => '1st Somewhere', 'groupid' => '1', 'groupNormalised' => '1', 'sectionid' => '10', 'sectionname' => 'Section 2', 'section' => 'cubs', 'isDefault' => '0', 'permissions' => { 'badge' => 100, 'member' => 100, 'user' => 100, 'register' => 100, 'contact' => 100, 'programme' => 100, 'originator' => 1, 'events' => 100, 'finance' => 100, 'flexi' => 100 } }
        ]

        expect($api).to receive(:post_query).with('api.php?action=getTerms').and_return(
          '9' => [
            { 'termid' => '1', 'name' => 'Term 1', 'sectionid' => '9', 'startdate' => (Date.today + 31).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 90).strftime('%Y-%m-%d') }
          ],
          '10' => [
            { 'termid' => '2', 'name' => 'Term 2', 'sectionid' => '10', 'startdate' => (Date.today + 31).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 90).strftime('%Y-%m-%d') },
            { 'termid' => '3', 'name' => 'Term 3', 'sectionid' => '10', 'startdate' => (Date.today + 91).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 180).strftime('%Y-%m-%d') }
          ]
        )
      end

      it 'From OSM' do
        terms = OSM::Term.get_all($api)
        expect(terms.size).to eq(3)
        expect(terms.map(&:id)).to eq([1, 2, 3])
        term = terms[0]
        expect(term.is_a?(OSM::Term)).to eq(true)
        expect(term.id).to eq(1)
        expect(term.name).to eq('Term 1')
        expect(term.start).to eq(Date.today + 31)
        expect(term.finish).to eq(Date.today + 90)
      end

      it 'From cache' do
        terms = OSM::Term.get_all($api)
        expect($api).not_to receive(:post_query)
        expect(OSM::Term.get_all($api)).to eq(terms)
      end
    end # Get all terms

    it 'Gets all terms for a section' do
      expect($api).to receive(:post_query).with('api.php?action=getTerms').and_return(
        '9' => [
          { 'termid' => '1', 'name' => 'Term 1', 'sectionid' => '9', 'startdate' => (Date.today + 31).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 90).strftime('%Y-%m-%d') }
        ],
        '10' => [
          { 'termid' => '2', 'name' => 'Term 2', 'sectionid' => '10', 'startdate' => (Date.today + 31).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 90).strftime('%Y-%m-%d') },
          { 'termid' => '3', 'name' => 'Term 3', 'sectionid' => '10', 'startdate' => (Date.today + 91).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 180).strftime('%Y-%m-%d') }
        ]
      )
      terms = OSM::Term.get_for_section(api: $api, section: 10)
      expect(terms.size).to eq(2)
      expect(terms.map(&:id)).to eq([2, 3])
    end

    describe 'Gets a term' do
      before :each do
        expect($api).to receive(:post_query).with('api.php?action=getTerms').and_return(
          '10' => [
            { 'termid' => '2', 'name' => 'Term 2', 'sectionid' => '10', 'startdate' => (Date.today + 31).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 90).strftime('%Y-%m-%d') },
            { 'termid' => '3', 'name' => 'Term 3', 'sectionid' => '10', 'startdate' => (Date.today + 91).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 180).strftime('%Y-%m-%d') }
          ]
        )
      end

      it 'From OSM' do
        term = OSM::Term.get(api: $api, id: 2)
        expect(term.is_a?(OSM::Term)).to eq(true)
        expect(term.id).to eq(2)
      end

      it 'From cache' do
        OSM::Term.get(api: $api, id: 2)
        expect($api).to_not receive(:post_query).with('api.php?action=getTerms')
        expect(OSM::Term.get(api: $api, id: 3).id).to eq(3)
      end
    end

    describe 'Find current term' do
      it 'Returns the current term for the section from all terms returned by OSM' do
        expect($api).to receive(:post_query).with('api.php?action=getTerms').and_return(
          '9' => [
            { 'termid' => '1', 'name' => 'Term 1', 'sectionid' => '9', 'startdate' => (Date.today - 90).strftime('%Y-%m-%d'), 'enddate' => (Date.today - 31).strftime('%Y-%m-%d') },
            { 'termid' => '2', 'name' => 'Term 2', 'sectionid' => '9', 'startdate' => (Date.today - 30).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 30).strftime('%Y-%m-%d') },
            { 'termid' => '3', 'name' => 'Term 3', 'sectionid' => '9', 'startdate' => (Date.today + 31).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 90).strftime('%Y-%m-%d') }
          ]
        )
        expect(OSM::Term.get_current_term_for_section(api: $api, section: 9).id).to eq(2)
      end

      it 'Raises an error if there is no current term' do
        expect($api).to receive(:post_query).with('api.php?action=getTerms').and_return(
          '9' => [
            { 'termid' => '1', 'name' => 'Term 1', 'sectionid' => '9', 'startdate' => (Date.today + 31).strftime('%Y-%m-%d'), 'enddate' => (Date.today + 31).strftime('%Y-%m-%d') }
          ]
        )
        expect { OSM::Term.get_current_term_for_section(api: $api, section: 9) }.to raise_error do |error|
          expect(error).to be_a(OSM::OSMError::NoCurrentTerm)
          expect(error.message).to eq('There is no current term for the section.')
          expect(error.section_id).to eq(9)
        end
      end
    end

    it 'Create a term' do
      post_data = {
        'term' => 'A Term',
        'start' => '2010-01-01',
        'end' => '2010-12-31',
        'termid' => '0'
      }

      allow(OSM::Term).to receive(:get_all) { [OSM::Term.new(id: 1, section_id: 1), OSM::Term.new(id: 9, section_id: 9)] }
      expect($api).to receive(:post_query).with('users.php?action=addTerm&sectionid=1', post_data: post_data).and_return('terms' => {})
      expect(OSM::Term).to receive(:cache_delete).with(api: $api, key: ['term', 1])
      expect(OSM::Term).to_not receive(:cache_delete).with(api: $api, key: ['term', 9])
      expect(OSM::Term).to receive(:cache_delete).with(api: $api, key: ['terms', $api.user_id])

      expect(OSM::Term.create(
        api: $api,
        section: 1,
        name: 'A Term',
        start: Date.new(2010, 01, 01),
        finish: Date.new(2010, 12, 31)
      )).to eq(true)
    end

    it 'Create a term (failed)' do
      post_data = {
        'term' => 'A Term',
        'start' => '2010-01-01',
        'end' => '2010-12-31',
        'termid' => '0'
      }

      allow(OSM::Term).to receive(:get_all) { [] }
      expect($api).to receive(:post_query).with('users.php?action=addTerm&sectionid=1', post_data: post_data).and_return({})

      expect(OSM::Term.create(
        api: $api,
        section: 1,
        name: 'A Term',
        start: Date.new(2010, 01, 01),
        finish: Date.new(2010, 12, 31)
      )).to eq(false)
    end

    it 'Update a term' do
      post_data = {
        'term' => 'A Term',
        'start' => '2010-01-01',
        'end' => '2010-12-31',
        'termid' => 2
      }
      allow(OSM::Term).to receive(:get_all) { [] }
      expect($api).to receive(:post_query).with('users.php?action=addTerm&sectionid=1', post_data: post_data).and_return('terms' => {})

      term = OSM::Term.new(id: 2, section_id: 1, name: 'A Term', start: Date.new(2010, 01, 01), finish: Date.new(2010, 12, 31))
      expect(term.update($api)).to eq(true)
    end

    it 'Update a term (failed)' do
      post_data = {
        'term' => 'A Term',
        'start' => '2010-01-01',
        'end' => '2010-12-31',
        'termid' => 2
      }
      allow(OSM::Term).to receive(:get_all) { [] }
      expect($api).to receive(:post_query).with('users.php?action=addTerm&sectionid=1', post_data: post_data).and_return({})

      term = OSM::Term.new(id: 2, section_id: 1, name: 'A Term', start: Date.new(2010, 01, 01), finish: Date.new(2010, 12, 31))
      expect(term.update($api)).to eq(false)
    end

    it 'Update a term (invalid term)' do
      term = OSM::Term.new
      expect { term.update($api) }.to raise_error(OSM::Error::InvalidObject)
    end

  end

end
