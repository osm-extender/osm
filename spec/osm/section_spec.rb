describe OSM::Section do

  before :each do
    @attributes = {
      id: 1,
      name: 'Name',
      subscription_level: 2,
      subscription_expires: (Date.today + 60).strftime('%Y-%m-%d'),
      type: :cubs,
      wizard: false,
      flexi_records: [],
      group_id: 3,
      group_name: '3rd Somewhere',
      gocardless: true,
      myscout_events_expires: (Date.today + 61).strftime('%Y-%m-%d'),
      myscout_badges_expires: (Date.today + 62).strftime('%Y-%m-%d'),
      myscout_programme_expires: (Date.today + 63).strftime('%Y-%m-%d'),
      myscout_details_expires: (Date.today + 64),
      myscout_events: true,
      myscout_badges: true,
      myscout_programme: true,
      myscout_payments: true,
      myscout_emails: { email1: true, email2: false },
      myscout_email_address_from: 'send_from@example.com',
      myscout_email_address_copy: '',
      myscout_badges_partial: true,
      myscout_programme_summary: true,
      myscout_programme_times: true,
      myscout_programme_show: 20,
      myscout_event_reminder_count: 4,
      myscout_event_reminder_frequency: 5,
      myscout_payment_reminder_count: 6,
      myscout_payment_reminder_frequency: 7,
      myscout_details: true,
      myscout_details_email_changes_to: 'notify-changes-to@example.com'
    }
  end


  it 'Create' do
    section = OSM::Section.new(@attributes)

    expect(section.id).to eq(1)
    expect(section.name).to eq('Name')
    expect(section.subscription_level).to eq(2)
    expect(section.subscription_expires).to eq(Date.today + 60)
    expect(section.type).to eq(:cubs)
    expect(section.group_id).to eq(3)
    expect(section.group_name).to eq('3rd Somewhere')
    expect(section.flexi_records).to eq([])
    expect(section.gocardless).to eq(true)
    expect(section.myscout_events_expires).to eq(Date.today + 61)
    expect(section.myscout_badges_expires).to eq(Date.today + 62)
    expect(section.myscout_programme_expires).to eq(Date.today + 63)
    expect(section.myscout_details_expires).to eq(Date.today + 64)
    expect(section.myscout_events).to eq(true)
    expect(section.myscout_badges).to eq(true)
    expect(section.myscout_programme).to eq(true)
    expect(section.myscout_payments).to eq(true)
    expect(section.myscout_emails).to eq(email1: true, email2: false)
    expect(section.myscout_email_address_from).to eq('send_from@example.com')
    expect(section.myscout_email_address_copy).to eq('')
    expect(section.myscout_badges_partial).to eq(true)
    expect(section.myscout_programme_summary).to eq(true)
    expect(section.myscout_programme_times).to eq(true)
    expect(section.myscout_programme_show).to eq(20)
    expect(section.myscout_event_reminder_count).to eq(4)
    expect(section.myscout_event_reminder_frequency).to eq(5)
    expect(section.myscout_payment_reminder_count).to eq(6)
    expect(section.myscout_payment_reminder_frequency).to eq(7)
    expect(section.myscout_details).to eq(true)
    expect(section.myscout_details_email_changes_to).to eq('notify-changes-to@example.com')
    expect(section.valid?).to eq(true)
  end


  it 'Create has sensible defaults' do
    section = OSM::Section.new

    expect(section.subscription_level).to eq(1)
    expect(section.subscription_expires).to be_nil
    expect(section.type).to eq(:unknown)
    expect(section.flexi_records).to eq([])
    expect(section.myscout_email_address_from).to eq('')
    expect(section.myscout_email_address_copy).to eq('')
    expect(section.myscout_details_email_changes_to).to eq('')
    expect(section.myscout_programme_show).to eq(0)
  end


  describe 'Using the API' do

    before :each do
      roles = [
        { 'sectionConfig' => '{"subscription_level":1,"subscription_expires":"2013-01-05","sectionType":"beavers","columnNames":{"column_names":"names"},"numscouts":10,"hasUsedBadgeRecords":true,"hasProgramme":true,"extraRecords":[{"name":"Flexi Record 1","extraid":"111"}],"wizard":"false","fields":{"fields":true},"intouch":{"intouch_fields":true},"mobFields":{"mobile_fields":true},"gocardless":"true","portal":{"paymentRemindFrequency":"7","paymentRemindCount":"6","eventRemindFrequency":"5","eventRemindCount":"4","badgesPartial":1,"programmeTimes":1,"programmeShow":"10","programmeSummary":1,"details":1,"contactNotificationEmail":"notify-changes-to@example.com","emailAddress":"send_from@example.com","emailAddressCopy":null,"payments":1,"badges":1,"emails":{"email1":"true","email2":"false"},"events":1,"programme":1},"portalExpires":{"events":"2013-01-06","eventsA":1,"badges":"2013-01-07","badgesA":1,"programme":"2013-01-08","programmeA":1,"details":"2013-01-09","detailsA":1},"hasSentTestSMS":true,"sms_remaining":8,"sms_sent":9}', 'groupname' => '3rd Somewhere', 'groupid' => '3', 'groupNormalised' => '1', 'sectionid' => '1', 'sectionname' => 'Section 1', 'section' => 'beavers', 'isDefault' => '1', 'permissions' => { 'badge' => 10, 'member' => 20, 'user' => 100, 'register' => 100, 'contact' => 100, 'programme' => 100, 'originator' => 1, 'events' => 100, 'finance' => 100, 'flexi' => 100 } },
        { 'sectionConfig' => "{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"cubs\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member's Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member's Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false},\"hasSentTestSMS\":true,\"sms_remaining\":8,\"sms_sent\":9}", 'groupname' => '1st Somewhere', 'groupid' => '1', 'groupNormalised' => '1', 'sectionid' => '2', 'sectionname' => 'Section 2', 'section' => 'cubs', 'isDefault' => '0', 'permissions' => { 'badge' => 100, 'member' => 100, 'user' => 100, 'register' => 100, 'contact' => 100, 'programme' => 100, 'originator' => 1, 'events' => 100, 'finance' => 100, 'flexi' => 100 } }
      ]
      allow($api).to receive(:post_query).with('api.php?action=getUserRoles') { roles }
    end

    describe 'Gets all sections' do
      it 'From OSM' do
        sections = OSM::Section.get_all(api: $api)
        expect(sections.map(&:id)).to eq([1, 2])

        section = sections[0]
        expect(section.id).to eq(1)
        expect(section.name).to eq('Section 1')
        expect(section.subscription_level).to eq(1)
        expect(section.subscription_expires).to eq(Date.new(2013, 1, 5))
        expect(section.type).to eq(:beavers)
        expect(section.group_id).to eq(3)
        expect(section.group_name).to eq('3rd Somewhere')
        expect(section.flexi_records.size).to eq(1)
        expect(section.flexi_records[0].id).to eq(111)
        expect(section.flexi_records[0].name).to eq('Flexi Record 1')
        expect(section.gocardless).to eq(true)
        expect(section.myscout_events_expires).to eq(Date.new(2013, 1, 6))
        expect(section.myscout_badges_expires).to eq(Date.new(2013, 1, 7))
        expect(section.myscout_programme_expires).to eq(Date.new(2013, 1, 8))
        expect(section.myscout_programme_show).to eq(10)
        expect(section.myscout_details_expires).to eq(Date.new(2013, 1, 9))
        expect(section.myscout_events).to eq(true)
        expect(section.myscout_badges).to eq(true)
        expect(section.myscout_programme).to eq(true)
        expect(section.myscout_payments).to eq(true)
        expect(section.myscout_emails).to eq(email1: true, email2: false)
        expect(section.myscout_email_address_from).to eq('send_from@example.com')
        expect(section.myscout_email_address_copy).to eq('')
        expect(section.myscout_badges_partial).to eq(true)
        expect(section.myscout_programme_summary).to eq(true)
        expect(section.myscout_programme_times).to eq(true)
        expect(section.myscout_event_reminder_count).to eq(4)
        expect(section.myscout_event_reminder_frequency).to eq(5)
        expect(section.myscout_payment_reminder_count).to eq(6)
        expect(section.myscout_payment_reminder_frequency).to eq(7)
        expect(section.myscout_details).to eq(true)
        expect(section.myscout_details_email_changes_to).to eq('notify-changes-to@example.com')
        expect(section.valid?).to eq(true)
      end

      it 'From cache' do
        sections = OSM::Section.get_all(api: $api)
        expect($api).not_to receive(:post_query)
        expect(OSM::Section.get_all(api: $api)).to eq(sections)
      end
    end

    describe 'Gets a section' do
      it 'From OSM' do
        section = OSM::Section.get(api: $api, id: 1)
        expect(section).not_to be_nil
        expect(section.id).to eq(1)
        expect(section.valid?).to eq(true)
      end

      it 'From cache' do
        section = OSM::Section.get(api: $api, id: 1)
        expect($api).not_to receive(:post_query)
        expect(OSM::Section.get(api: $api, id: 1)).to eq(section)
      end
    end


    describe "Gets the section's notepad" do
      it 'From OSM' do
        expect($api).to receive(:post_query).with('api.php?action=getNotepads').and_return({"1" => {"raw" => "Section 1", "html" => "<p>Section 1</p>"}, "2" => {"raw" => "Section 2", "html" => "<p>Section 2</p>"}})
        section = OSM::Section.new(id: 1)
        expect(section.get_notepad($api)).to eq('Section 1')
      end

      it 'From cache' do
        expect($api).to receive(:post_query).with('api.php?action=getNotepads').and_return({"1" => {"raw" => "Section 1", "html" => "<p>Section 1</p>"}, "2" => {"raw" => "Section 2", "html" => "<p>Section 2</p>"}})
        section = OSM::Section.new(id: 1)
        expect(section.get_notepad($api)).to eq('Section 1')
        expect($api).not_to receive(:post_query).with('api.php?action=getNotepads')
        expect(section.get_notepad($api)).to eq('Section 1')
      end
    end

    it "Sets the section's notepad (success)" do
      expect($api).to receive(:post_query).with('users.php?action=updateNotepad&sectionid=1', post_data: { 'raw' => 'content' }).and_return('ok' => true)
      section = OSM::Section.new(id: 1)
      expect(section.set_notepad(api: $api, content: 'content')).to eq(true)
    end

    it "Sets the section's notepad (fail)" do
      expect($api).to receive(:post_query).with('users.php?action=updateNotepad&sectionid=1', post_data: { 'raw' => 'content' }).and_return('ok' => false)
      section = OSM::Section.new(id: 1)
      expect(section.set_notepad(api: $api, content: 'content')).to eq(false)
    end

  end


  describe 'Compare two sections' do

    it 'They match' do
      section1 = OSM::Section.new(@attributes)
      section2 = OSM::Section.new(@attributes)

      expect(section1).to eq(section2)
    end

    it "They don't match" do
      section1 = OSM::Section.new(@attributes)
      section2 = OSM::Section.new(@attributes.merge(id: 2))

      expect(section1).not_to eq(section2)
    end

  end


  it 'Sorts by Group Name, section type (age order) then name' do
    section1 = OSM::Section.new(@attributes.merge(group_id: 1, group_name: '1st Somewhere', type: :beavers, name: 'a'))
    section2 = OSM::Section.new(@attributes.merge(group_id: 2, group_name: '2nd Somewhere', type: :beavers, name: 'a'))
    section3 = OSM::Section.new(@attributes.merge(group_id: 2, group_name: '2nd Somewhere', type: :cubs, name: 'a'))
    section4 = OSM::Section.new(@attributes.merge(group_id: 2, group_name: '2nd Somewhere', type: :cubs, name: 'b'))

    data = [section2, section4, section3, section1]
    expect(data.sort).to eq([section1, section2, section3, section4])
  end


  describe 'Correctly works out the section type' do
    unknown   = OSM::Section.new(type: :abc)
    beavers   = OSM::Section.new(type: :beavers)
    cubs      = OSM::Section.new(type: :cubs)
    scouts    = OSM::Section.new(type: :scouts)
    explorers = OSM::Section.new(type: :explorers)
    network   = OSM::Section.new(type: :network)
    adults    = OSM::Section.new(type: :adults)
    waiting   = OSM::Section.new(type: :waiting)

    { beavers: beavers, cubs: cubs, scouts: scouts, explorers: explorers, network: network, :adults => adults, :waiting => waiting, :unknown => unknown }.each do |section_type, section|
      it "For a #{section_type} section" do
        [:beavers, :cubs, :scouts, :explorers, :network, :adults, :waiting].each do |type|
          expect(section.send("#{type.to_s}?")).to eq(section_type == type)
        end
      end
    end
  end


  describe 'Correctly works out if the section is a youth section' do
    unknown =   OSM::Section.new(type: :abc)
    beavers =   OSM::Section.new(type: :beavers)
    cubs =      OSM::Section.new(type: :cubs)
    scouts =    OSM::Section.new(type: :scouts)
    explorers = OSM::Section.new(type: :explorers)
    network =   OSM::Section.new(type: :network)
    adults =    OSM::Section.new(type: :adults)
    waiting =   OSM::Section.new(type: :waiting)

    [beavers, cubs, scouts, explorers].each do |section|
      it "For a #{section.type} section" do
        expect(section.youth_section?).to eq(true)
      end
    end
    [network, adults, waiting, unknown].each do |section|
      it "For a #{section.type} section" do
        expect(section.youth_section?).to eq(false)
      end
    end
  end

  describe 'Corretly works out the subscription level' do

    it 'Bronze' do
      section = OSM::Section.new(subscription_level: 1)
      expect(section.bronze?).to eq(true)
      expect(section.silver?).to eq(false)
      expect(section.gold?).to eq(false)
      expect(section.gold_plus?).to eq(false)
    end

    it 'Silver' do
      section = OSM::Section.new(subscription_level: 2)
      expect(section.bronze?).to eq(false)
      expect(section.silver?).to eq(true)
      expect(section.gold?).to eq(false)
      expect(section.gold_plus?).to eq(false)
    end

    it 'Gold' do
      section = OSM::Section.new(subscription_level: 3)
      expect(section.bronze?).to eq(false)
      expect(section.silver?).to eq(false)
      expect(section.gold?).to eq(true)
      expect(section.gold_plus?).to eq(false)
    end

    it 'Gold+' do
      section = OSM::Section.new(subscription_level: 4)
      expect(section.bronze?).to eq(false)
      expect(section.silver?).to eq(false)
      expect(section.gold?).to eq(false)
      expect(section.gold_plus?).to eq(true)
    end

    it 'Unknown' do
      section = OSM::Section.new(subscription_level: 0)
      expect(section.bronze?).to eq(false)
      expect(section.silver?).to eq(false)
      expect(section.gold?).to eq(false)
      expect(section.gold_plus?).to eq(false)
    end

  end # describe

  describe 'Correctly works out if a section has a subscription of at least' do

    it 'Bronze' do
      section = OSM::Section.new(subscription_level: 1)
      expect(section.subscription_at_least?(:bronze)).to eq(true)
      expect(section.subscription_at_least?(:silver)).to eq(false)
      expect(section.subscription_at_least?(:gold)).to eq(false)
      expect(section.subscription_at_least?(:gold_plus)).to eq(false)
      expect(section.subscription_at_least?(1)).to eq(true)
      expect(section.subscription_at_least?(2)).to eq(false)
      expect(section.subscription_at_least?(3)).to eq(false)
      expect(section.subscription_at_least?(4)).to eq(false)
    end

    it 'Silver' do
      section = OSM::Section.new(subscription_level: 2)
      expect(section.subscription_at_least?(:bronze)).to eq(true)
      expect(section.subscription_at_least?(:silver)).to eq(true)
      expect(section.subscription_at_least?(:gold)).to eq(false)
      expect(section.subscription_at_least?(:gold_plus)).to eq(false)
      expect(section.subscription_at_least?(1)).to eq(true)
      expect(section.subscription_at_least?(2)).to eq(true)
      expect(section.subscription_at_least?(3)).to eq(false)
      expect(section.subscription_at_least?(4)).to eq(false)
    end

    it 'Gold' do
      section = OSM::Section.new(subscription_level: 3)
      expect(section.subscription_at_least?(:bronze)).to eq(true)
      expect(section.subscription_at_least?(:silver)).to eq(true)
      expect(section.subscription_at_least?(:gold)).to eq(true)
      expect(section.subscription_at_least?(:gold_plus)).to eq(false)
      expect(section.subscription_at_least?(1)).to eq(true)
      expect(section.subscription_at_least?(2)).to eq(true)
      expect(section.subscription_at_least?(3)).to eq(true)
      expect(section.subscription_at_least?(4)).to eq(false)
    end

    it 'Gold+' do
      section = OSM::Section.new(subscription_level: 4)
      expect(section.subscription_at_least?(:bronze)).to eq(true)
      expect(section.subscription_at_least?(:silver)).to eq(true)
      expect(section.subscription_at_least?(:gold)).to eq(true)
      expect(section.subscription_at_least?(:gold_plus)).to eq(true)
      expect(section.subscription_at_least?(1)).to eq(true)
      expect(section.subscription_at_least?(2)).to eq(true)
      expect(section.subscription_at_least?(3)).to eq(true)
      expect(section.subscription_at_least?(4)).to eq(true)
    end

    it 'Unknown' do
      section = OSM::Section.new(subscription_level: 0)
      expect(section.subscription_at_least?(:bronze)).to eq(false)
      expect(section.subscription_at_least?(:silver)).to eq(false)
      expect(section.subscription_at_least?(:gold)).to eq(false)
      expect(section.subscription_at_least?(:gold_plus)).to eq(false)
      expect(section.subscription_at_least?(1)).to eq(false)
      expect(section.subscription_at_least?(2)).to eq(false)
      expect(section.subscription_at_least?(3)).to eq(false)
      expect(section.subscription_at_least?(4)).to eq(false)
    end

  end # describe

end



describe 'Online Scout Manager API Strangeness' do

  it 'handles a section with no type' do
    body = [{ 'sectionConfig' => "{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member\'s Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member\'s Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[{\"name\":\"Subs\",\"extraid\":\"529\"}],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}", 'groupname' => '1st Somewhere', 'groupid' => '1', 'groupNormalised' => '1', 'sectionid' => '1', 'sectionname' => 'Section 1', 'section' => 'cubs', 'isDefault' => '1', 'permissions' => { 'badge' => 100, 'member' => 100, 'user' => 100, 'register' => 100, 'contact' => 100, 'programme' => 100, 'originator' => 1, 'events' => 100, 'finance' => 100, 'flexi' => 100 } }]
    allow($api).to receive(:post_query).with('api.php?action=getUserRoles') { body }

    sections = OSM::Section.get_all(api: $api)
    expect(sections.size).to eq(1)
    section = sections[0]
    expect(section).not_to be_nil
    expect(section.type).to eq(:unknown)
  end

  it 'handles strange extra records when getting roles' do
    body = [{ 'sectionConfig' => "{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"cubs\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member\'s Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member\'s Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[[\"1\",{\"name\":\"Subs\",\"extraid\":\"529\"}],[\"2\",{\"name\":\"Subs 2\",\"extraid\":\"530\"}]],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}", 'groupname' => '1st Somewhere', 'groupid' => '1', 'groupNormalised' => '1', 'sectionid' => '1', 'sectionname' => 'Section 1', 'section' => 'cubs', 'isDefault' => '1', 'permissions' => { 'badge' => 100, 'member' => 100, 'user' => 100, 'register' => 100, 'contact' => 100, 'programme' => 100, 'originator' => 1, 'events' => 100, 'finance' => 100, 'flexi' => 100 } }]
    allow($api).to receive(:post_query).with('api.php?action=getUserRoles') { body }

    sections = OSM::Section.get_all(api: $api)
    expect(sections.size).to eq(1)
    expect(sections[0]).not_to be_nil
  end

  it 'handles an empty array representing no notepads' do
    body = [{ 'sectionConfig' => '{"subscription_level":1,"subscription_expires":"2013-01-05","sectionType":"beavers","columnNames":{"column_names":"names"},"numscouts":10,"hasUsedBadgeRecords":true,"hasProgramme":true,"extraRecords":[{"name":"Flexi Record 1","extraid":"111"}],"wizard":"false","fields":{"fields":true},"intouch":{"intouch_fields":true},"mobFields":{"mobile_fields":true}}', 'groupname' => '3rd Somewhere', 'groupid' => '3', 'groupNormalised' => '1', 'sectionid' => '1', 'sectionname' => 'Section 1', 'section' => 'beavers', 'isDefault' => '1', 'permissions' => { 'badge' => 10, 'member' => 20, 'user' => 100, 'register' => 100, 'contact' => 100, 'programme' => 100, 'originator' => 1, 'events' => 100, 'finance' => 100, 'flexi' => 100 } }]
    allow($api).to receive(:post_query).with('api.php?action=getUserRoles') { body }
    allow($api).to receive(:post_query).with('api.php?action=getNotepads') { [] }

    section = OSM::Section.get(api: $api, id: 1)
    expect(section).not_to be_nil
    expect(section.get_notepad($api)).to eq('')
  end

  it "skips a 'discount' section" do
    body = [
      { 'sectionConfig' => "{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member's Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member's Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}", 'groupname' => '3rd Somewhere', 'groupid' => '3', 'groupNormalised' => '1', 'sectionid' => '1', 'sectionname' => 'Section 1', 'section' => 'beavers', 'isDefault' => '1', 'permissions' => { 'badge' => 100, 'member' => 100, 'user' => 100, 'register' => 100, 'contact' => 100, 'programme' => 100, 'originator' => 1, 'events' => 100, 'finance' => 100, 'flexi' => 100 } },
      { 'sectionConfig' => '{"code":1,"districts":["Loddon","Kennet"]}', 'groupname' => 'Berkshire', 'groupid' => '2', 'groupNormalised' => '1', 'sectionid' => '3', 'sectionname' => 'County Admin', 'section' => 'discount', 'isDefault' => '0', 'permissions' => { 'districts' => ['Loddon'] } }
    ]
    allow($api).to receive(:post_query).with('api.php?action=getUserRoles') { body }

    sections = OSM::Section.get_all(api: $api)
    expect(sections.size).to eq(1)
    section = sections[0]
    expect(section).not_to be_nil
    expect(section.id).to eq(1)
  end

  it 'handles section config being either a Hash or a JSON encoded Hash' do
    body = [
      { 'sectionConfig' => '{"subscription_level":1,"subscription_expires":"2013-01-05","sectionType":"beavers","columnNames":{"column_names":"names"},"numscouts":10,"hasUsedBadgeRecords":true,"hasProgramme":true,"extraRecords":[{"name":"Flexi Record 1","extraid":"111"}],"wizard":"false","fields":{"fields":true},"intouch":{"intouch_fields":true},"mobFields":{"mobile_fields":true}}', 'groupname' => '3rd Somewhere', 'groupid' => '3', 'groupNormalised' => '1', 'sectionid' => '1', 'sectionname' => 'Section 1', 'section' => 'beavers', 'isDefault' => '1', 'permissions' => { 'badge' => 10, 'member' => 20, 'user' => 100, 'register' => 100, 'contact' => 100, 'programme' => 100, 'originator' => 1, 'events' => 100, 'finance' => 100, 'flexi' => 100 } },
      { 'sectionConfig' => { 'subscription_level' => 3, 'subscription_expires' => '2013-01-05', 'sectionType' => 'cubs', 'columnNames' => { 'phone1' => 'Home Phone', 'phone2' => 'Parent 1 Phone', 'address' => "Member's Address", 'phone3' => 'Parent 2 Phone', 'address2' => 'Address 2', 'phone4' => 'Alternate Contact Phone', 'subs' => 'Gender', 'email1' => 'Parent 1 Email', 'medical' => 'Medical / Dietary', 'email2' => 'Parent 2 Email', 'ethnicity' => 'Gift Aid', 'email3' => "Member's Email", 'religion' => 'Religion', 'email4' => 'Email 4', 'school' => 'School' }, 'numscouts' => 10, 'hasUsedBadgeRecords' => true, 'hasProgramme' => true, 'extraRecords' => [], 'wizard' => 'false', 'fields' => { 'email1' => true, 'email2' => true, 'email3' => true, 'email4' => false, 'address' => true, 'address2' => false, 'phone1' => true, 'phone2' => true, 'phone3' => true, 'phone4' => true, 'school' => false, 'religion' => true, 'ethnicity' => true, 'medical' => true, 'patrol' => true, 'subs' => true, 'saved' => true }, 'intouch' => { 'address' => true, 'address2' => false, 'email1' => false, 'email2' => false, 'email3' => false, 'email4' => false, 'phone1' => true, 'phone2' => true, 'phone3' => true, 'phone4' => true, 'medical' => false }, 'mobFields' => { 'email1' => false, 'email2' => false, 'email3' => false, 'email4' => false, 'address' => true, 'address2' => false, 'phone1' => true, 'phone2' => true, 'phone3' => true, 'phone4' => true, 'school' => false, 'religion' => false, 'ethnicity' => true, 'medical' => true, 'patrol' => true, 'subs' => false } }, 'groupname' => '1st Somewhere', 'groupid' => '1', 'groupNormalised' => '1', 'sectionid' => '2', 'sectionname' => 'Section 2', 'section' => 'cubs', 'isDefault' => '0', 'permissions' => { 'badge' => 100, 'member' => 100, 'user' => 100, 'register' => 100, 'contact' => 100, 'programme' => 100, 'originator' => 1, 'events' => 100, 'finance' => 100, 'flexi' => 100 } }
    ]
    allow($api).to receive(:post_query).with('api.php?action=getUserRoles') { body }

    sections = OSM::Section.get_all(api: $api)
    expect(sections.size).to eq(2)
    expect(sections[0]).not_to be_nil
    expect(sections[1]).not_to be_nil
  end

  it 'Handles user having access to no sections' do
    allow($api).to receive(:post_query).with('api.php?action=getUserRoles') { [{ 'isDefault' => '1' }] }

    sections = OSM::Section.get_all(api: $api)
    expect(sections).to eq([])
  end

end
