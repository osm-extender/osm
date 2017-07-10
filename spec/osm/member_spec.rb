describe Osm::Member do

  it 'Create' do
    attributes = {
      id: 1,
      section_id: 2,
      first_name: 'First',
      last_name: 'Last',
      date_of_birth: '2000-01-02',
      grouping_id: '3',
      grouping_leader: 0,
      grouping_label: 'Grouping',
      grouping_leader_label: '6er',
      age: '06 / 07',
      gender: :other,
      joined_movement: '2006-01-02',
      started_section: '2006-01-07',
      finished_section: '2007-12-31',
      additional_information: { '12_3' => '123' },
      additional_information_labels: { '12_3' => 'Label for 123' },
      contact: Osm::Member::MemberContact.new(postcode: 'A'),
      primary_contact: Osm::Member::PrimaryContact.new(postcode: 'B'),
      secondary_contact: Osm::Member::PrimaryContact.new(postcode: 'C'),
      emergency_contact: Osm::Member::EmergencyContact.new(postcode: 'D'),
      doctor: Osm::Member::DoctorContact.new(postcode: 'E')
    }
    member = Osm::Member.new(attributes)

    expect(member.id).to eq(1)
    expect(member.section_id).to eq(2)
    expect(member.first_name).to eq('First')
    expect(member.last_name).to eq('Last')
    expect(member.date_of_birth).to eq(Date.new(2000, 1, 2))
    expect(member.grouping_id).to eq(3)
    expect(member.grouping_leader).to eq(0)
    expect(member.grouping_label).to eq('Grouping')
    expect(member.grouping_leader_label).to eq('6er')
    expect(member.age).to eq('06 / 07')
    expect(member.gender).to eq(:other)
    expect(member.joined_movement).to eq(Date.new(2006, 1, 2))
    expect(member.started_section).to eq(Date.new(2006, 1, 7))
    expect(member.finished_section).to eq(Date.new(2007, 12, 31))
    expect(member.additional_information).to eq('12_3' => '123')
    expect(member.additional_information_labels).to eq('12_3' => 'Label for 123')
    expect(member.contact.postcode).to eq('A')
    expect(member.primary_contact.postcode).to eq('B')
    expect(member.secondary_contact.postcode).to eq('C')
    expect(member.emergency_contact.postcode).to eq('D')
    expect(member.doctor.postcode).to eq('E')
    expect(member.valid?).to eq(true)
  end


  it 'Provides full name' do
    expect(Osm::Member.new(first_name: 'First').name).to eq('First')
    expect(Osm::Member.new(last_name: 'Last').name).to eq('Last')
    expect(Osm::Member.new(first_name: 'First', last_name: 'Last').name).to eq('First Last')
    expect(Osm::Member.new(first_name: 'First', last_name: 'Last').name('*')).to eq('First*Last')
  end


  it 'Tells if member is a leader' do
    expect(Osm::Member.new(grouping_id: -2).leader?).to eq(true)  # In the leader grouping
    expect(Osm::Member.new(grouping_id: 2).leader?).to eq(false)  # In a youth grouping
    expect(Osm::Member.new(grouping_id: 0).leader?).to eq(false)  # Not in a grouping
  end

  it 'Tells if member is a youth member' do
    expect(Osm::Member.new(grouping_id: -2).youth?).to eq(false)  # In the leader grouping
    expect(Osm::Member.new(grouping_id: 2).youth?).to eq(true)  # In a youth grouping
    expect(Osm::Member.new(grouping_id: 0).youth?).to eq(false)  # Not in a grouping
  end

  it 'Provides each part of age' do
    data = {
      age: '06/07'
    }
    member = Osm::Member.new(data)

    expect(member.age_years).to eq(6)
    expect(member.age_months).to eq(7)
  end

  it 'Tells if the member is male' do
    expect(Osm::Member.new(gender: :male).male?).to eq(true)
    expect(Osm::Member.new(gender: :female).male?).to eq(false)
    expect(Osm::Member.new(gender: :other).male?).to eq(false)
    expect(Osm::Member.new(gender: :unspecified).male?).to eq(false)
    expect(Osm::Member.new(gender: nil).male?).to eq(false)
  end

  it 'Tells if the member is female' do
    expect(Osm::Member.new(gender: :female).female?).to eq(true)
    expect(Osm::Member.new(gender: :male).female?).to eq(false)
    expect(Osm::Member.new(gender: :other).female?).to eq(false)
    expect(Osm::Member.new(gender: :unspecified).female?).to eq(false)
    expect(Osm::Member.new(gender: nil).female?).to eq(false)
  end


  describe 'Tells if the member is currently in the section' do
    it 'Today' do
      expect(Osm::Member.new(started_section: Date.yesterday).current?).to eq(true)
      expect(Osm::Member.new(started_section: Date.today).current?).to eq(true)
      expect(Osm::Member.new(started_section: Date.tomorrow).current?).to eq(false)
      expect(Osm::Member.new(started_section: Date.yesterday, finished_section: Date.yesterday).current?).to eq(false)
      expect(Osm::Member.new(started_section: Date.yesterday, finished_section: Date.today).current?).to eq(true)
      expect(Osm::Member.new(started_section: Date.yesterday, finished_section: Date.tomorrow).current?).to eq(true)
    end

    it 'Another date' do
      yesterday = Date.new(2014, 10, 15)
      today = Date.new(2014, 10, 16)
      tomorrow = Date.new(2014, 10, 17)
      expect(Osm::Member.new(started_section: yesterday).current?(today)).to eq(true)
      expect(Osm::Member.new(started_section: today).current?(today)).to eq(true)
      expect(Osm::Member.new(started_section: tomorrow).current?(today)).to eq(false)
      expect(Osm::Member.new(started_section: yesterday, finished_section: yesterday).current?(today)).to eq(false)
      expect(Osm::Member.new(started_section: yesterday, finished_section: today).current?(today)).to eq(true)
      expect(Osm::Member.new(started_section: yesterday, finished_section: tomorrow).current?(today)).to eq(true)
    end
  end


  it 'Sorts by section_id, grouping_id, grouping_leader (descending), last_name then first_name' do
    m1 = Osm::Member.new(section_id: 1, grouping_id: 1, grouping_leader: 1, last_name: 'a', first_name: 'a')
    m2 = Osm::Member.new(section_id: 2, grouping_id: 1, grouping_leader: 1, last_name: 'a', first_name: 'a')
    m3 = Osm::Member.new(section_id: 2, grouping_id: 2, grouping_leader: 1, last_name: 'a', first_name: 'a')
    m4 = Osm::Member.new(section_id: 2, grouping_id: 2, grouping_leader: 0, last_name: 'a', first_name: 'a')
    m5 = Osm::Member.new(section_id: 2, grouping_id: 2, grouping_leader: 0, last_name: 'a', first_name: 'a')
    m6 = Osm::Member.new(section_id: 2, grouping_id: 2, grouping_leader: 0, last_name: 'b', first_name: 'a')
    m7 = Osm::Member.new(section_id: 2, grouping_id: 2, grouping_leader: 0, last_name: 'b', first_name: 'b')

    data = [m4, m2, m3, m1, m7, m6, m5]
    expect(data.sort).to eq([m1, m2, m3, m4, m5, m6, m7])
  end

  describe 'Get contact details' do
    before :each do
      @member = Osm::Member.new(
        first_name: 'A',
        last_name:  'Member',
        contact:    Osm::Member::MemberContact.new(
          first_name: 'A',
          last_name: 'Member',
          email_1:  'enabled.member@example.com',
          email_2:  'disabled.member@example.com',
          receive_email_1: true,
          receive_email_2: false,
          phone_1:  '1111111',
          phone_2:  '2222222',
          receive_phone_1: true,
          receive_phone_2: false
        ),
        primary_contact: Osm::Member::PrimaryContact.new(
          first_name: 'Primary',
          last_name:  'Contact',
          email_1:    'enabled.primary@example.com',
          email_2:    'disabled.primary@example.com',
          receive_email_1: true,
          receive_email_2: false,
          phone_1:    '3333333',
          phone_2:    '4444444',
          receive_phone_1: true,
          receive_phone_2: false
        ),
        secondary_contact: Osm::Member::SecondaryContact.new(
          first_name: 'Secondary',
          last_name:  'Contact',
          email_1:    'enabled.secondary@example.com',
          email_2:    'disabled.secondary@example.com',
          receive_email_1: true,
          receive_email_2: false,
          phone_1:    '5555555',
          phone_2:    '6666666',
          receive_phone_1: true,
          receive_phone_2: false
        ),
        emergency_contact: Osm::Member::EmergencyContact.new(
          first_name: 'Emergency',
          last_name:  'Contact',
          email_1:    'emergency@example.com',
          phone_1:    '7777777'
        ),
        doctor_contact: Osm::Member::DoctorContact.new(
          first_name: 'Doctor',
          last_name:  'Contact',
          email_1:    'doctor@example.com',
          phone_1:    '8888888'
        )
      )
      @member_nil_contacts = Osm::Member.new(
        first_name: 'A',
        last_name:  'Member',
        contact:    nil,
        primary_contact: nil,
        secondary_contact: nil,
        emergency_contact: nil,
        doctor_contact: nil
      )
    end

    it '#all_emails' do
      expect(@member.all_emails).to eq [
        'enabled.member@example.com',
        'disabled.member@example.com',
        'enabled.primary@example.com',
        'disabled.primary@example.com',
        'enabled.secondary@example.com',
        'disabled.secondary@example.com'
      ]
      expect(@member_nil_contacts.all_emails).to eq []
    end
    it '#all_emails_with_name' do
      expect(@member.all_emails_with_name).to eq [
        '"A Member" <enabled.member@example.com>',
        '"A Member" <disabled.member@example.com>',
        '"Primary Contact" <enabled.primary@example.com>',
        '"Primary Contact" <disabled.primary@example.com>',
        '"Secondary Contact" <enabled.secondary@example.com>',
        '"Secondary Contact" <disabled.secondary@example.com>'
      ]
      expect(@member_nil_contacts.all_emails_with_name).to eq []
    end

    it '#enabled_emails' do
      expect(@member.enabled_emails).to eq [
        'enabled.member@example.com',
        'enabled.primary@example.com',
        'enabled.secondary@example.com'
      ]
      expect(@member_nil_contacts.enabled_emails).to eq []
    end
    it '#enabled_emails_with_name' do
      expect(@member.enabled_emails_with_name).to eq [
        '"A Member" <enabled.member@example.com>',
        '"Primary Contact" <enabled.primary@example.com>',
        '"Secondary Contact" <enabled.secondary@example.com>'
      ]
      expect(@member_nil_contacts.enabled_emails_with_name).to eq []
    end

    it '#all_phones' do
      expect(@member.all_phones).to eq ['1111111', '2222222', '3333333', '4444444', '5555555', '6666666']
      expect(@member_nil_contacts.all_phones).to eq []
    end
    it '#enabled_phones' do
      expect(@member.enabled_phones).to eq ['1111111', '3333333', '5555555']
      expect(@member_nil_contacts.enabled_phones).to eq []
    end
  end


  describe 'Using the API' do

    describe 'Get from OSM' do

      it 'Normal data returned from OSM' do
        body = {
          'status' => true,
          'error' => nil,
          'data' => {
            '123' => {
              'active' => true,
              'age' => '12 / 00',
              'date_of_birth' => '2000-03-08',
              'end_date' => '2010-06-03',
              'first_name' => 'John',
              'joined' => '2008-07-12',
              'last_name' => 'Smith',
              'member_id' => 123,
              'patrol' => 'Leaders',
              'patrol_id' => -2,
              'patrol_role_level' => 1,
              'patrol_role_level_label' => 'Assistant leader',
              'section_id' => 1,
              'started' => '2006-07-17',
              'custom_data' => {
                '1' => { '2' => 'Primary', '3' => 'Contact', '7' => 'Address 1', '8' => 'Address 2', '9' => 'Address 3', '10' => 'Address 4', '11' => 'Postcode', '12' => 'primary@example.com', '13' => 'yes', '14' => '', '15' => '', '18' => '01234 567890', '19' => 'yes', '20' => '0987 654321', '21' => '', '8441' => 'Data for 8441' },
                '2' => { '2' => 'Secondary', '3' => 'Contact', '7' => 'Address 1', '8' => 'Address 2', '9' => 'Address 3', '10' => 'Address 4', '11' => 'Postcode', '12' => 'secondary@example.com', '13' => 'yes', '14' => '', '15' => '', '18' => '01234 567890', '19' => 'yes', '20' => '0987 654321', '21' => '', '8442' => 'Data for 8442' },
                '3' => { '2' => 'Emergency', '3' => 'Contact', '7' => 'Address 1', '8' => 'Address 2', '9' => 'Address 3', '10' => 'Address 4', '11' => 'Postcode', '12' => 'emergency@example.com', '14' => '', '18' => '01234 567890', '20' => '0987 654321', '21' => '', '8443' => 'Data for 8443' },
                '4' => { '2' => 'Doctor', '3' => 'Contact', '7' => 'Address 1', '8' => 'Address 2', '9' => 'Address 3', '10' => 'Address 4', '11' => 'Postcode', '18' => '01234 567890', '20' => '0987 654321', '21' => '', '54' => 'Surgery', '8444' => 'Data for 8444' },
                '5' => { '4848' => 'Data for 4848' },
                '6' => { '7' => 'Address 1', '8' => 'Address 2', '9' => 'Address 3', '10' => 'Address 4', '11' => 'Postcode', '12' => 'member@example.com', '13' => 'yes', '14' => '', '15' => '', '18' => '01234 567890', '19' => 'yes', '20' => '0987 654321', '21' => '', '8446' => 'Data for 8446' },
                '7' => { '34' => 'Unspecified' }
              }
            }
          },
          'meta' => {
            'leader_count' => 20,
            'member_count' => 30,
            'status' => true,
            'structure' => [
              { 'group_id' => 1, 'description' => '', 'identifier' => 'contact_primary_1', 'name' => 'Primary Contact 1', 'columns' => [
                { 'column_id' => 2, 'group_column_id' => '1_2', 'label' => 'First Name', 'varname' => 'firstname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 3, 'group_column_id' => '1_3', 'label' => 'Last Name', 'varname' => 'lastname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 7, 'group_column_id' => '1_7', 'label' => 'Address 1', 'varname' => 'address1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 8, 'group_column_id' => '1_8', 'label' => 'Address 2', 'varname' => 'address2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 9, 'group_column_id' => '1_9', 'label' => 'Address 3', 'varname' => 'address3', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 10, 'group_column_id' => '1_10', 'label' => 'Address 4', 'varname' => 'address4', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 11, 'group_column_id' => '1_11', 'label' => 'Postcode', 'varname' => 'postcode', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 12, 'group_column_id' => '1_12', 'label' => 'Email 1', 'varname' => 'email1', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120 },
                { 'column_id' => 14, 'group_column_id' => '1_14', 'label' => 'Email 2', 'varname' => 'email2', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120 },
                { 'column_id' => 18, 'group_column_id' => '1_18', 'label' => 'Phone 1', 'varname' => 'phone1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 20, 'group_column_id' => '1_20', 'label' => 'Phone 2', 'varname' => 'phone2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 8441, 'group_column_id' => '1_8441', 'label' => 'Label for 8441', 'varname' => 'label_for_8441', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] },
              { 'group_id' => 2, 'description' => '', 'identifier' => 'contact_primary_2', 'name' => 'Primary Contact 2', 'columns' => [
                { 'column_id' => 2, 'group_column_id' => '2_2', 'label' => 'First Name', 'varname' => 'firstname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 3, 'group_column_id' => '2_3', 'label' => 'Last Name', 'varname' => 'lastname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 7, 'group_column_id' => '2_7', 'label' => 'Address 1', 'varname' => 'address1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 8, 'group_column_id' => '2_8', 'label' => 'Address 2', 'varname' => 'address2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 9, 'group_column_id' => '2_9', 'label' => 'Address 3', 'varname' => 'address3', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 10, 'group_column_id' => '2_10', 'label' => 'Address 4', 'varname' => 'address4', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 11, 'group_column_id' => '2_11', 'label' => 'Postcode', 'varname' => 'postcode', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 12, 'group_column_id' => '2_12', 'label' => 'Email 1', 'varname' => 'email1', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120 },
                { 'column_id' => 14, 'group_column_id' => '2_14', 'label' => 'Email 2', 'varname' => 'email2', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120 },
                { 'column_id' => 18, 'group_column_id' => '2_18', 'label' => 'Phone 1', 'varname' => 'phone1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 20, 'group_column_id' => '2_20', 'label' => 'Phone 2', 'varname' => 'phone2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 8442, 'group_column_id' => '2_8442', 'label' => 'Label for 8442', 'varname' => 'label_for_8442', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] },
              { 'group_id' => 3, 'description' => '', 'identifier' => 'emergency', 'name' => 'Emergency Contact', 'columns' => [
                { 'column_id' => 2, 'group_column_id' => '3_2', 'label' => 'First Name', 'varname' => 'firstname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 3, 'group_column_id' => '3_3', 'label' => 'Last Name', 'varname' => 'lastname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 7, 'group_column_id' => '3_7', 'label' => 'Address 1', 'varname' => 'address1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 8, 'group_column_id' => '3_8', 'label' => 'Address 2', 'varname' => 'address2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 9, 'group_column_id' => '3_9', 'label' => 'Address 3', 'varname' => 'address3', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 10, 'group_column_id' => '3_10', 'label' => 'Address 4', 'varname' => 'address4', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 11, 'group_column_id' => '3_11', 'label' => 'Postcode', 'varname' => 'postcode', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 12, 'group_column_id' => '3_12', 'label' => 'Email 1', 'varname' => 'email1', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120 },
                { 'column_id' => 14, 'group_column_id' => '3_14', 'label' => 'Email 2', 'varname' => 'email2', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120 },
                { 'column_id' => 18, 'group_column_id' => '3_18', 'label' => 'Phone 1', 'varname' => 'phone1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 20, 'group_column_id' => '3_20', 'label' => 'Phone 2', 'varname' => 'phone2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 8443, 'group_column_id' => '3_8443', 'label' => 'Label for 8443', 'varname' => 'label_for_8443', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] },
              { 'group_id' => 4, 'description' => '', 'identifier' => 'doctor', 'name' => "Doctor's Surgery", 'columns' => [
                { 'column_id' => 2, 'group_column_id' => '4_2', 'label' => 'First Name', 'varname' => 'firstname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 3, 'group_column_id' => '4_3', 'label' => 'Last Name', 'varname' => 'lastname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 54, 'group_column_id' => '4_54', 'label' => 'Surgery', 'varname' => 'surgery', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 7, 'group_column_id' => '4_7', 'label' => 'Address 1', 'varname' => 'address1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 8, 'group_column_id' => '4_8', 'label' => 'Address 2', 'varname' => 'address2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 9, 'group_column_id' => '4_9', 'label' => 'Address 3', 'varname' => 'address3', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 10, 'group_column_id' => '4_10', 'label' => 'Address 4', 'varname' => 'address4', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 11, 'group_column_id' => '4_11', 'label' => 'Postcode', 'varname' => 'postcode', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 18, 'group_column_id' => '4_18', 'label' => 'Phone 1', 'varname' => 'phone1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 20, 'group_column_id' => '4_20', 'label' => 'Phone 2', 'varname' => 'phone2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 8444, 'group_column_id' => '4_8444', 'label' => 'Label for 8444', 'varname' => 'label_for_8444', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] },
              { 'group_id' => 6, 'description' => '', 'identifier' => 'contact_member', 'name' => 'Member', 'columns' => [
                { 'column_id' => 2, 'group_column_id' => '6_2', 'label' => 'First Name', 'varname' => 'firstname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 3, 'group_column_id' => '6_3', 'label' => 'Last Name', 'varname' => 'lastname', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 7, 'group_column_id' => '6_7', 'label' => 'Address 1', 'varname' => 'address1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 8, 'group_column_id' => '6_8', 'label' => 'Address 2', 'varname' => 'address2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 9, 'group_column_id' => '6_9', 'label' => 'Address 3', 'varname' => 'address3', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 10, 'group_column_id' => '6_10', 'label' => 'Address 4', 'varname' => 'address4', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 11, 'group_column_id' => '6_11', 'label' => 'Postcode', 'varname' => 'postcode', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 12, 'group_column_id' => '6_12', 'label' => 'Email 1', 'varname' => 'email1', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120 },
                { 'column_id' => 14, 'group_column_id' => '6_14', 'label' => 'Email 2', 'varname' => 'email2', 'read_only' => 'no', 'required' => 'no', 'type' => 'email', 'width' => 120 },
                { 'column_id' => 18, 'group_column_id' => '6_18', 'label' => 'Phone 1', 'varname' => 'phone1', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 20, 'group_column_id' => '6_20', 'label' => 'Phone 2', 'varname' => 'phone2', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 },
                { 'column_id' => 8446, 'group_column_id' => '6_8446', 'label' => 'Label for 8446', 'varname' => 'label_for_8446', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] },
              { 'group_id' => 5, 'description' => 'This allows you to add  extra information for your members.', 'identifier' => 'customisable_data', 'name' => 'Customisable Data', 'columns' => [
                { 'column_id' => 4848, 'group_column_id' => '5_4848', 'label' => 'Label for 4848', 'varname' => 'label_for_4848', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] },
              { 'group_id' => 7, 'description' => '', 'identifier' => 'floating', 'name' => 'Floating', 'columns' => [
                { 'column_id' => 34, 'group_column_id' => '7_34', 'label' => 'Gender', 'varname' => 'gender', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] }
            ]
          }
        }
        expect($api).to receive(:post_query).with('ext/members/contact/grid/?action=getMembers', post_data: { 'section_id' => 1, 'term_id' => 2 }).and_return(body)

        members = Osm::Member.get_for_section(api: $api, section: 1, term: 2)
        expect(members.size).to eq(1)
        member = members[0]
        expect(member.id).to eq(123)
        expect(member.section_id).to eq(1)
        expect(member.first_name).to eq('John')
        expect(member.last_name).to eq('Smith')
        expect(member.date_of_birth).to eq(Date.new(2000, 3, 8))
        expect(member.grouping_id).to eq(-2)
        expect(member.grouping_leader).to eq(1)
        expect(member.grouping_label).to eq('Leaders')
        expect(member.grouping_leader_label).to eq('Assistant leader')
        expect(member.age).to eq('12 / 00')
        expect(member.gender).to eq(:unspecified)
        expect(member.joined_movement).to eq(Date.new(2006, 7, 17))
        expect(member.started_section).to eq(Date.new(2008, 7, 12))
        expect(member.finished_section).to eq(Date.new(2010, 6, 3))
        expect(member.additional_information).to eq(4848 => 'Data for 4848')
        expect(member.additional_information_labels).to eq(4848 => 'Label for 4848')
        expect(member.contact.first_name).to eq('John')
        expect(member.contact.last_name).to eq('Smith')
        expect(member.contact.address_1).to eq('Address 1')
        expect(member.contact.address_2).to eq('Address 2')
        expect(member.contact.address_3).to eq('Address 3')
        expect(member.contact.address_4).to eq('Address 4')
        expect(member.contact.postcode).to eq('Postcode')
        expect(member.contact.phone_1).to eq('01234 567890')
        expect(member.contact.receive_phone_1).to eq(true)
        expect(member.contact.phone_2).to eq('0987 654321')
        expect(member.contact.receive_phone_2).to eq(false)
        expect(member.contact.email_1).to eq('member@example.com')
        expect(member.contact.receive_email_1).to eq(true)
        expect(member.contact.email_2).to eq('')
        expect(member.contact.receive_email_2).to eq(false)
        expect(member.contact.additional_information).to eq(8446 => 'Data for 8446')
        expect(member.contact.additional_information_labels).to eq(8446 => 'Label for 8446')
        expect(member.primary_contact.first_name).to eq('Primary')
        expect(member.primary_contact.last_name).to eq('Contact')
        expect(member.primary_contact.address_1).to eq('Address 1')
        expect(member.primary_contact.address_2).to eq('Address 2')
        expect(member.primary_contact.address_3).to eq('Address 3')
        expect(member.primary_contact.address_4).to eq('Address 4')
        expect(member.primary_contact.postcode).to eq('Postcode')
        expect(member.primary_contact.phone_1).to eq('01234 567890')
        expect(member.primary_contact.receive_phone_1).to eq(true)
        expect(member.primary_contact.phone_2).to eq('0987 654321')
        expect(member.primary_contact.receive_phone_2).to eq(false)
        expect(member.primary_contact.email_1).to eq('primary@example.com')
        expect(member.primary_contact.receive_email_1).to eq(true)
        expect(member.primary_contact.email_2).to eq('')
        expect(member.primary_contact.receive_email_2).to eq(false)
        expect(member.primary_contact.additional_information).to eq(8441 => 'Data for 8441')
        expect(member.primary_contact.additional_information_labels).to eq(8441 => 'Label for 8441')
        expect(member.secondary_contact.first_name).to eq('Secondary')
        expect(member.secondary_contact.last_name).to eq('Contact')
        expect(member.secondary_contact.address_1).to eq('Address 1')
        expect(member.secondary_contact.address_2).to eq('Address 2')
        expect(member.secondary_contact.address_3).to eq('Address 3')
        expect(member.secondary_contact.address_4).to eq('Address 4')
        expect(member.secondary_contact.postcode).to eq('Postcode')
        expect(member.secondary_contact.phone_1).to eq('01234 567890')
        expect(member.secondary_contact.receive_phone_1).to eq(true)
        expect(member.secondary_contact.phone_2).to eq('0987 654321')
        expect(member.secondary_contact.receive_phone_2).to eq(false)
        expect(member.secondary_contact.email_1).to eq('secondary@example.com')
        expect(member.secondary_contact.receive_email_1).to eq(true)
        expect(member.secondary_contact.email_2).to eq('')
        expect(member.secondary_contact.receive_email_2).to eq(false)
        expect(member.secondary_contact.additional_information).to eq(8442 => 'Data for 8442')
        expect(member.secondary_contact.additional_information_labels).to eq(8442 => 'Label for 8442')
        expect(member.emergency_contact.first_name).to eq('Emergency')
        expect(member.emergency_contact.last_name).to eq('Contact')
        expect(member.emergency_contact.address_1).to eq('Address 1')
        expect(member.emergency_contact.address_2).to eq('Address 2')
        expect(member.emergency_contact.address_3).to eq('Address 3')
        expect(member.emergency_contact.address_4).to eq('Address 4')
        expect(member.emergency_contact.postcode).to eq('Postcode')
        expect(member.emergency_contact.phone_1).to eq('01234 567890')
        expect(member.emergency_contact.phone_2).to eq('0987 654321')
        expect(member.emergency_contact.email_1).to eq('emergency@example.com')
        expect(member.emergency_contact.email_2).to eq('')
        expect(member.emergency_contact.additional_information).to eq(8443 => 'Data for 8443')
        expect(member.emergency_contact.additional_information_labels).to eq(8443 => 'Label for 8443')
        expect(member.doctor.first_name).to eq('Doctor')
        expect(member.doctor.last_name).to eq('Contact')
        expect(member.doctor.surgery).to eq('Surgery')
        expect(member.doctor.address_1).to eq('Address 1')
        expect(member.doctor.address_2).to eq('Address 2')
        expect(member.doctor.address_3).to eq('Address 3')
        expect(member.doctor.address_4).to eq('Address 4')
        expect(member.doctor.postcode).to eq('Postcode')
        expect(member.doctor.phone_1).to eq('01234 567890')
        expect(member.doctor.phone_2).to eq('0987 654321')
        expect(member.doctor.additional_information).to eq(8444 => 'Data for 8444')
        expect(member.doctor.additional_information_labels).to eq(8444 => 'Label for 8444')
        expect(member.valid?).to eq(true)
      end

      it 'Handles disabled contacts' do
        body = {
          'status' => true,
          'error' => nil,
          'data' => {
            '123' => {
              'active' => true,
              'age' => '12 / 00',
              'date_of_birth' => '2000-03-08',
              'end_date' => '2010-06-03',
              'first_name' => 'John',
              'joined' => '2008-07-12',
              'last_name' => 'Smith',
              'member_id' => 123,
              'patrol' => 'Leaders',
              'patrol_id' => -2,
              'patrol_role_level' => 1,
              'patrol_role_level_label' => 'Assistant leader',
              'section_id' => 1,
              'started' => '2006-07-17',
              'custom_data' => {
                '5' => { '4848' => 'Data for 4848' },
                '7' => { '34' => 'Unspecified' }
              }
            }
          },
          'meta' => {
            'leader_count' => 20,
            'member_count' => 30,
            'status' => true,
            'structure' => [
              { 'group_id' => 5, 'description' => 'This allows you to add  extra information for your members.', 'identifier' => 'customisable_data', 'name' => 'Customisable Data', 'columns' => [
                { 'column_id' => 4848, 'group_column_id' => '5_4848', 'label' => 'Label for 4848', 'varname' => 'label_for_4848', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] },
              { 'group_id' => 7, 'description' => '', 'identifier' => 'floating', 'name' => 'Floating', 'columns' => [
                { 'column_id' => 34, 'group_column_id' => '7_34', 'label' => 'Gender', 'varname' => 'gender', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] }
            ]
          }
        }
        expect($api).to receive(:post_query).with('ext/members/contact/grid/?action=getMembers', post_data: { 'section_id' => 1, 'term_id' => 2 }).and_return(body)

        members = Osm::Member.get_for_section(api: $api, section: 1, term: 2)
        expect(members.size).to eq(1)
        member = members[0]
        expect(member.id).to eq(123)
        expect(member.contact).to eq(nil)
        expect(member.primary_contact).to eq(nil)
        expect(member.secondary_contact).to eq(nil)
        expect(member.emergency_contact).to eq(nil)
        expect(member.doctor).to eq(nil)
        expect(member.valid?).to eq(true)
      end

      it 'Handles no custom data' do
        body = {
          'status' => true,
          'error' => nil,
          'data' => {
            '123' => {
              'active' => true,
              'age' => '12 / 00',
              'date_of_birth' => '2000-03-08',
              'end_date' => '2010-06-03',
              'first_name' => 'John',
              'joined' => '2008-07-12',
              'last_name' => 'Smith',
              'member_id' => 123,
              'patrol' => 'Leaders',
              'patrol_id' => -2,
              'patrol_role_level' => 1,
              'patrol_role_level_label' => 'Assistant leader',
              'section_id' => 1,
              'started' => '2006-07-17',
              'custom_data' => {
                '7' => { '34' => 'Unspecified' }
              }
            }
          },
          'meta' => {
            'leader_count' => 20,
            'member_count' => 30,
            'status' => true,
            'structure' => [
              { 'group_id' => 5, 'description' => 'This allows you to add  extra information for your members.', 'identifier' => 'customisable_data', 'name' => 'Customisable Data', 'columns' => [
                { 'column_id' => 4848, 'group_column_id' => '5_4848', 'label' => 'Label for 4848', 'varname' => 'label_for_4848', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] },
              { 'group_id' => 7, 'description' => '', 'identifier' => 'floating', 'name' => 'Floating', 'columns' => [
                { 'column_id' => 34, 'group_column_id' => '7_34', 'label' => 'Gender', 'varname' => 'gender', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] }
            ]
          }
        }
        expect($api).to receive(:post_query).with('ext/members/contact/grid/?action=getMembers', post_data: { 'section_id' => 1, 'term_id' => 2 }).and_return(body)

        members = Osm::Member.get_for_section(api: $api, section: 1, term: 2)
        expect(members.size).to eq(1)
        member = members[0]
        expect(member.id).to eq(123)
        expect(member.additional_information).to eq({})
        expect(member.valid?).to eq(true)
      end

      it 'Handles missing floating data' do
        body = {
          'status' => true,
          'error' => nil,
          'data' => {
            '123' => {
              'active' => true,
              'age' => '12 / 00',
              'date_of_birth' => '2000-03-08',
              'end_date' => '2010-06-03',
              'first_name' => 'John',
              'joined' => '2008-07-12',
              'last_name' => 'Smith',
              'member_id' => 123,
              'patrol' => 'Leaders',
              'patrol_id' => -2,
              'patrol_role_level' => 1,
              'patrol_role_level_label' => 'Assistant leader',
              'section_id' => 1,
              'started' => '2006-07-17',
              'custom_data' => {
                '5' => { '4848' => 'Data for 4848' }
              }
            }
          },
          'meta' => {
            'leader_count' => 20,
            'member_count' => 30,
            'status' => true,
            'structure' => [
              { 'group_id' => 5, 'description' => 'This allows you to add  extra information for your members.', 'identifier' => 'customisable_data', 'name' => 'Customisable Data', 'columns' => [
                { 'column_id' => 4848, 'group_column_id' => '5_4848', 'label' => 'Label for 4848', 'varname' => 'label_for_4848', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] },
              { 'group_id' => 7, 'description' => '', 'identifier' => 'floating', 'name' => 'Floating', 'columns' => [
                { 'column_id' => 34, 'group_column_id' => '7_34', 'label' => 'Gender', 'varname' => 'gender', 'read_only' => 'no', 'required' => 'no', 'type' => 'text', 'width' => 120 }
              ] }
            ]
          }
        }
        expect($api).to receive(:post_query).with('ext/members/contact/grid/?action=getMembers', post_data: { 'section_id' => 1, 'term_id' => 2 }).and_return(body)

        members = Osm::Member.get_for_section(api: $api, section: 1, term: 2)
        expect(members.size).to eq(1)
        member = members[0]
        expect(member.id).to eq(123)
        expect(member.gender).to eq(nil)
        expect(member.valid?).to eq(true)
      end

      it 'Handles an empty data array' do
        body = {
          'status' => true,
          'error' => nil,
          'data' => [],
          'meta' => {}
        }
        expect($api).to receive(:post_query).with('ext/members/contact/grid/?action=getMembers', post_data: { 'section_id' => 1, 'term_id' => 2 }).and_return(body)

        expect(Osm::Member.get_for_section(api: $api, section: 1, term: 2)).to eq([])
      end

    end


    describe 'Create in OSM' do

      before :each do
        attributes = {
          section_id: 2,
          first_name: 'First',
          last_name: 'Last',
          date_of_birth: '2000-01-02',
          grouping_id: '3',
          grouping_leader: 0,
          grouping_label: 'Grouping',
          grouping_leader_label: '6er',
          age: '06 / 07',
          gender: :other,
          joined_movement: '2006-01-02',
          started_section: '2006-01-07',
          finished_section: '2007-12-31',
          additional_information: { '12_3' => '123' },
          additional_information_labels: { '12_3' => 'Label for 123' },
          contact: Osm::Member::MemberContact.new(postcode: 'A'),
          primary_contact: Osm::Member::PrimaryContact.new(postcode: 'B'),
          secondary_contact: Osm::Member::PrimaryContact.new(postcode: 'C'),
          emergency_contact: Osm::Member::EmergencyContact.new(postcode: 'D'),
          doctor: Osm::Member::DoctorContact.new(postcode: 'E')
        }
        @member = Osm::Member.new(attributes)
      end

      it 'Success' do
        expect($api).to receive(:post_query).with('users.php?action=newMember', post_data: {
          'sectionid' => 2,
          'firstname' => 'First',
          'lastname' => 'Last',
          'dob' => '2000-01-02',
          'started' => '2006-01-02',
          'startedsection' => '2006-01-07'
        }).and_return('result' => 'ok', 'scoutid' => 577743)

        allow(@member).to receive(:update) { true }
        allow(Osm::Term).to receive(:get_for_section) { [Osm::Term.new(id: 3)] }
        expect(@member).to receive(:cache_delete).with(api: $api, key: ['members', 2, 3])

        expect(@member.create($api)).to eq(true)
        expect(@member.id).to eq(577743)
      end

      it 'Failed the create stage in OSM' do
        expect($api).to receive(:post_query).with('users.php?action=newMember', post_data: { 'firstname' => 'First', 'lastname' => 'Last', 'dob' => '2000-01-02', 'started' => '2006-01-02', 'startedsection' => '2006-01-07', 'sectionid' => 2 }).and_return({})
        allow(Osm::Term).to receive(:get_for_section) { [Osm::Term.new(id: 3)] }
        expect(@member).to_not receive(:cache_delete)
        expect(@member.create($api)).to eq(false)
      end

      it 'Failed the update stage in OSM' do
        expect($api).to receive(:post_query).with('users.php?action=newMember', post_data: {
          'sectionid' => 2,
          'firstname' => 'First',
          'lastname' => 'Last',
          'dob' => '2000-01-02',
          'started' => '2006-01-02',
          'startedsection' => '2006-01-07'
        }).and_return('result' => 'ok', 'scoutid' => 577743)

        allow(@member).to receive(:update) { false }
        allow(Osm::Term).to receive(:get_for_section) { [Osm::Term.new(id: 3)] }
        expect(@member).to receive(:cache_delete).with(api: $api, key: ['members', 2, 3])

        expect(@member.create($api)).to eq(nil)
        expect(@member.id).to eq(577743)
      end

      it 'Raises error if member is invalid' do
        expect { Osm::Member.new.create($api) }.to raise_error(Osm::Error::InvalidObject, 'member is invalid')
      end

      it 'Raises error if member exists in OSM (has an ID)' do
        expect { Osm::Member.new(id: 12345).create($api) }.to raise_error(Osm::OSMError, 'the member already exists in OSM')
      end

    end


    describe 'Update in OSM' do

      before :each do
        attributes = {
          id: 1,
          section_id: 2,
          first_name: 'First',
          last_name: 'Last',
          date_of_birth: '2000-01-02',
          grouping_id: '3',
          grouping_leader: 0,
          grouping_label: 'Grouping',
          grouping_leader_label: '6er',
          age: '06 / 07',
          gender: :other,
          joined_movement: '2006-01-02',
          started_section: '2006-01-07',
          finished_section: '2007-12-31',
          additional_information: DirtyHashy[ 123, '123' ],
          additional_information_labels: { 123 => 'Label for 123' },
          contact: Osm::Member::MemberContact.new(postcode: 'A'),
          primary_contact: Osm::Member::PrimaryContact.new(postcode: 'B'),
          secondary_contact: Osm::Member::SecondaryContact.new(postcode: 'C'),
          emergency_contact: Osm::Member::EmergencyContact.new(postcode: 'D'),
          doctor: Osm::Member::DoctorContact.new(postcode: 'E', additional_information: DirtyHashy['test_var', 'This is a test'])
        }
        @member = Osm::Member.new(attributes)
      end

      it 'Only updated fields' do
        expect($api).to receive(:post_query).with('ext/members/contact/?action=update', post_data: {
          'sectionid' => 2,
          'scoutid' => 1,
          'column' => 'firstname',
          'value' => 'John'
        }).and_return('ok' => true)

        expect($api).to receive(:post_query).with('ext/customdata/?action=updateColumn&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 7,
          'column_id' => 34,
          'value' => 'Unspecified'
        }).and_return('data' => { 'value' => 'Unspecified' })

        expect($api).to receive(:post_query).with('ext/customdata/?action=update&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 6,
          'data[address1]' => 'Address 1'
        }).and_return('status' => true)

        expect($api).to receive(:post_query).with('ext/customdata/?action=update&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 1,
          'data[address2]' => 'Address 2'
        }).and_return('status' => true)

        expect($api).to receive(:post_query).with('ext/customdata/?action=update&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 2,
          'data[address3]' => 'Address 3'
        }).and_return('status' => true)

        expect($api).to receive(:post_query).with('ext/customdata/?action=update&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 3,
          'data[address4]' => 'Address 4'
        }).and_return('status' => true)

        expect($api).to receive(:post_query).with('ext/customdata/?action=update&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 4,
          'data[surgery]' => 'Surgery',
          'data[test_var]' => 'This is still a test'
        }).and_return('status' => true)

        expect($api).to receive(:post_query).with('ext/customdata/?action=updateColumn&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 5,
          'column_id' => 123,
          'value' => '321'
        }).and_return('data' => { 'value' => '321' })

        allow(Osm::Term).to receive(:get_for_section) { [Osm::Term.new(id: 3)] }
        expect(@member).to receive(:cache_delete).with(api: $api, key: ['members', 2, 3])

        @member.first_name = 'John'
        @member.gender = :unspecified
        @member.additional_information[123] = '321'
        @member.contact.address_1 = 'Address 1'
        @member.primary_contact.address_2 = 'Address 2'
        @member.secondary_contact.address_3 = 'Address 3'
        @member.emergency_contact.address_4 = 'Address 4'
        @member.doctor.surgery = 'Surgery'
        @member.doctor.additional_information['test_var'] = 'This is still a test'
        expect(@member.update($api)).to eq(true)
      end

      it 'All fields' do
        { 'firstname' => 'First', 'lastname' => 'Last', 'patrolid' => 3, 'patrolleader' => 0, 'dob' => '2000-01-02', 'startedsection' => '2006-01-07', 'started' => '2006-01-02' }.each do |key, value|
          expect($api).to receive(:post_query).with('ext/members/contact/?action=update', post_data: {
            'sectionid' => 2,
            'scoutid' => 1,
            'column' => key,
            'value' => value
          }).and_return('ok' => true)
        end

        expect($api).to receive(:post_query).with('ext/customdata/?action=updateColumn&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 7,
          'column_id' => 34,
          'value' => 'Other'
        }).and_return('data' => { 'value' => 'Other' })

        expect($api).to receive(:post_query).with('ext/customdata/?action=updateColumn&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 5,
          'column_id' => 123,
          'value' => '123'
        }).and_return('data' => { 'value' => '123' })

        { 6 => 'A', 1 => 'B', 2 => 'C' }.each do |group_id, postcode|
          expect($api).to receive(:post_query).with('ext/customdata/?action=update&section_id=2', post_data: {
            'context' => 'members',
            'associated_type' => 'member',
            'associated_id' => 1,
            'group_id' => group_id,
            'data[firstname]' => nil,
            'data[lastname]' => nil,
            'data[address1]' => nil,
            'data[address2]' => nil,
            'data[address3]' => nil,
            'data[address4]' => nil,
            'data[postcode]' => postcode,
            'data[phone1]' => nil,
            'data[phone2]' => nil,
            'data[email1]' => nil,
            'data[email1_leaders]' => false,
            'data[email2]' => nil,
            'data[email2_leaders]' => false,
            'data[phone1_sms]' => false,
            'data[phone2_sms]' => false
          }).and_return('status' => true)
        end

        expect($api).to receive(:post_query).with('ext/customdata/?action=update&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 3,
          'data[firstname]' => nil,
          'data[lastname]' => nil,
          'data[address1]' => nil,
          'data[address2]' => nil,
          'data[address3]' => nil,
          'data[address4]' => nil,
          'data[postcode]' => 'D',
          'data[phone1]' => nil,
          'data[phone2]' => nil,
          'data[email1]' => nil,
          'data[email2]' => nil
        }).and_return('status' => true)

        expect($api).to receive(:post_query).with('ext/customdata/?action=update&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 4,
          'data[firstname]' => nil,
          'data[lastname]' => nil,
          'data[surgery]' => nil,
          'data[address1]' => nil,
          'data[address2]' => nil,
          'data[address3]' => nil,
          'data[address4]' => nil,
          'data[postcode]' => 'E',
          'data[phone1]' => nil,
          'data[phone2]' => nil,
          'data[test_var]' => 'This is a test'
        }).and_return('status' => true)

        allow(Osm::Term).to receive(:get_for_section) { [Osm::Term.new(id: 3)] }
        expect(@member).to receive(:cache_delete).with(api: $api, key: ['members', 2, 3])

        expect(@member.update($api, force: true)).to eq(true)
      end

      it 'Failed to update in OSM' do
        @member.first_name = 'John'
        allow($api).to receive(:post_query) { {} }
        expect(@member).to_not receive(:cache_delete)
        expect(@member.update($api)).to eq(false)
      end

      it 'Raises error if member is invalid' do
        expect { Osm::Member.new.create($api) }.to raise_error(Osm::Error::InvalidObject, 'member is invalid')
      end

      it 'Handles disabled contacts' do
        @member.contact = nil
        @member.primary_contact = nil
        @member.secondary_contact = nil
        @member.emergency_contact = nil
        @member.doctor = nil
        allow($api).to receive(:post_query) { {} }
        expect(@member.update($api)).to eq(true)
      end

      it 'When setting data to a blank string' do
        expect($api).to receive(:post_query).with('ext/members/contact/?action=update', post_data: {
          'sectionid' => 2,
          'scoutid' => 1,
          'column' => 'firstname',
          'value' => ''
        }).and_return('ok' => true)

        expect($api).to receive(:post_query).with('ext/customdata/?action=updateColumn&section_id=2', post_data: {
          'context' => 'members',
          'associated_type' => 'member',
          'associated_id' => 1,
          'group_id' => 5,
          'column_id' => 123,
          'value' => ''
        }).and_return('data' => { 'value' => nil })

        allow(Osm::Term).to receive(:get_for_section) { [] }

        allow(@member).to receive('valid?') { true }
        @member.first_name = ''
        @member.additional_information[123] = ''
        expect(@member.update($api)).to eq(true)
      end

    end

    it 'Get Photo link' do
      member = Osm::Member.new(
        id: 1,
        section_id: 2,
        first_name: 'First',
        last_name: 'Last',
        date_of_birth: '2000-01-02',
        started_section: '2006-01-02',
        joined_movement: '2006-01-03',
        grouping_id: '3',
        grouping_leader: 0,
        grouping_label: 'Grouping',
        grouping_leader_label: '',
        additional_information: {},
        additional_information_labels: {},
        contact: Osm::Member::MemberContact.new(),
        primary_contact: Osm::Member::PrimaryContact.new(),
        secondary_contact: Osm::Member::PrimaryContact.new(),
        emergency_contact: Osm::Member::EmergencyContact.new(),
        doctor: Osm::Member::DoctorContact.new()
      )
      allow($api).to receive(:post_query).with('ext/members/contact/images/member.php?sectionid=2&scoutid=1&bw=false').and_return('abcdef')

      expect(member.get_photo($api)).to eq('abcdef')
    end


    describe 'Get My.SCOUT link' do

      before :each do
        @member = Osm::Member.new(
          id: 1,
          section_id: 2,
          first_name: 'First',
          last_name: 'Last',
          date_of_birth: '2000-01-02',
          started_section: '2006-01-02',
          joined_movement: '2006-01-03',
          grouping_id: '3',
          grouping_leader: 0,
          grouping_label: 'Grouping',
          grouping_leader_label: '',
          additional_information: {},
          additional_information_labels: {},
          contact: Osm::Member::MemberContact.new(),
          primary_contact: Osm::Member::PrimaryContact.new(),
          secondary_contact: Osm::Member::PrimaryContact.new(),
          emergency_contact: Osm::Member::EmergencyContact.new(),
          doctor: Osm::Member::DoctorContact.new()
        )
      end

      it 'Get the key' do
        expect($api).to receive(:post_query).with('api.php?action=getMyScoutKey&sectionid=2&scoutid=1').and_return('ok' => true, 'key' => 'KEY-HERE')
        expect(@member.myscout_link_key($api)).to eq('KEY-HERE')
      end

      it 'Default' do
        allow(@member).to receive(:myscout_link_key) { 'KEY-HERE' }
        expect(@member.myscout_link($api)).to eq('https://www.onlinescoutmanager.co.uk/parents/badges.php?sc=1&se=2&c=KEY-HERE')
      end

      it 'Payments' do
        allow(@member).to receive(:myscout_link_key) { 'KEY-HERE' }
        expect(@member.myscout_link($api, link_to: :payments)).to eq('https://www.onlinescoutmanager.co.uk/parents/payments.php?sc=1&se=2&c=KEY-HERE')
      end

      it 'Events' do
        allow(@member).to receive(:myscout_link_key) { 'KEY-HERE' }
        expect(@member.myscout_link($api, link_to: :events)).to eq('https://www.onlinescoutmanager.co.uk/parents/events.php?sc=1&se=2&c=KEY-HERE')
      end

      it 'Specific Event' do
        allow(@member).to receive(:myscout_link_key) { 'KEY-HERE' }
        expect(@member.myscout_link($api, link_to: :events, item_id: 2)).to eq('https://www.onlinescoutmanager.co.uk/parents/events.php?sc=1&se=2&c=KEY-HERE&e=2')
      end

      it 'Programme' do
        allow(@member).to receive(:myscout_link_key) { 'KEY-HERE' }
        expect(@member.myscout_link($api, link_to: :programme)).to eq('https://www.onlinescoutmanager.co.uk/parents/programme.php?sc=1&se=2&c=KEY-HERE')
      end

      it 'Badges' do
        allow(@member).to receive(:myscout_link_key) { 'KEY-HERE' }
        expect(@member.myscout_link($api, link_to: :badges)).to eq('https://www.onlinescoutmanager.co.uk/parents/badges.php?sc=1&se=2&c=KEY-HERE')
      end

      it 'Notice board' do
        allow(@member).to receive(:myscout_link_key) { 'KEY-HERE' }
        expect(@member.myscout_link($api, link_to: :notice)).to eq('https://www.onlinescoutmanager.co.uk/parents/notice.php?sc=1&se=2&c=KEY-HERE')
      end

      it 'Personal details' do
        allow(@member).to receive(:myscout_link_key) { 'KEY-HERE' }
        expect(@member.myscout_link($api, link_to: :details)).to eq('https://www.onlinescoutmanager.co.uk/parents/details.php?sc=1&se=2&c=KEY-HERE')
      end

      it 'Census detail entry' do
        allow(@member).to receive(:myscout_link_key) { 'KEY-HERE' }
        expect(@member.myscout_link($api, link_to: :census)).to eq('https://www.onlinescoutmanager.co.uk/parents/census.php?sc=1&se=2&c=KEY-HERE')
      end

      it 'Gift Aid consent' do
        allow(@member).to receive(:myscout_link_key) { 'KEY-HERE' }
        expect(@member.myscout_link($api, link_to: :giftaid)).to eq('https://www.onlinescoutmanager.co.uk/parents/giftaid.php?sc=1&se=2&c=KEY-HERE')
      end

    end

  end

end
