describe Osm::Email do

  describe 'Get emails for contacts' do

    it 'Single member' do
      expect($api).to receive(:post_query).with('/ext/members/email/?action=getSelectedEmailsFromContacts&sectionid=1&scouts=2', post_data: { 'contactGroups' => '["contact_primary_member"]' }).and_return(        'emails'=>{
          '2'=>{
            'emails'=>['john@example.com'],
            'firstname'=>'John',
            'lastname'=>'Smith'
          }
        },
        'count'=>1)

      result = Osm::Email.get_emails_for_contacts(api: $api, section: 1, contacts: :member, members: 2)
      expect(result).to eq(        '2' => {
          'emails' => ['john@example.com'],
          'firstname' => 'John',
          'lastname' => 'Smith'
        })
    end

    it 'Several members' do
      expect($api).to receive(:post_query).with('/ext/members/email/?action=getSelectedEmailsFromContacts&sectionid=1&scouts=2,3', post_data: { 'contactGroups' => '["contact_primary_member"]' }).and_return(        'emails'=>{
          '2'=>{
            'emails'=>['john@example.com'],
            'firstname'=>'John',
            'lastname'=>'Smith'
          },
          '3'=>{
            'emails'=>['jane@example.com','jane2@example.com'],
            'firstname'=>'Jane',
            'lastname'=>'Smith'
          }
        },
        'count'=>3)

      result = Osm::Email.get_emails_for_contacts(api: $api, section: 1, contacts: :member, members: [2,3])
      expect(result).to eq(        '2' => {
          'emails' => ['john@example.com'],
          'firstname' => 'John',
          'lastname' => 'Smith'
        },
        '3' => {
          'emails' => ['jane@example.com', 'jane2@example.com'],
          'firstname' => 'Jane',
          'lastname' => 'Smith'
        })
    end

    it 'Requires at least one contact' do
      expect($api).not_to receive(:post_query)
      expect{ Osm::Email.get_emails_for_contacts(api: $api, section: 1, contacts: [], members: [2]) }.to raise_error ArgumentError, 'You must pass at least one contact'
    end

    it 'Checks for invalid contacts' do
      expect($api).not_to receive(:post_query)
      expect{ Osm::Email.get_emails_for_contacts(api: $api, section: 1, contacts: [:invalid_contact], members: [2]) }.to raise_error ArgumentError, 'Invalid contact - :invalid_contact'
    end

    it 'Requires at least one member' do
      expect($api).not_to receive(:post_query)
      expect{ Osm::Email.get_emails_for_contacts(api: $api, section: 1, contacts: [:primary], members: []) }.to raise_error ArgumentError, 'You must pass at least one member'
    end

    it 'Handles no emails returned' do
      expect($api).to receive(:post_query).with('/ext/members/email/?action=getSelectedEmailsFromContacts&sectionid=1&scouts=1', post_data: { 'contactGroups' => '["contact_primary_1"]' }).and_return({})
      expect(Osm::Email.get_emails_for_contacts(api: $api, section: 1, members: 1, contacts: [:primary])).to be false
    end

    it 'Handles no data hash returned' do
      expect($api).to receive(:post_query).with('/ext/members/email/?action=getSelectedEmailsFromContacts&sectionid=1&scouts=1', post_data: { 'contactGroups' => '["contact_primary_1"]' }).and_return([])
      expect(Osm::Email.get_emails_for_contacts(api: $api, section: 1, members: 1, contacts: [:primary])).to be false
    end

  end # describe Get emails for conatcts

  describe 'Send email' do

    it 'With cc' do
      expect($api).to receive(:post_query).with('ext/members/email/?action=send', post_data: {
        'sectionid' => 1,
        'emails' => '{"2":{"firstname":"John","lastname":"Smith","emails":["john@example.com"]}}',
        'scouts' => '2',
        'cc' => 'cc@example.com',
        'from' => 'Sender <from@example.com>',
        'subject' => 'Subject of email',
        'body' => 'Body of email',
      }){ { 'ok'=>true } }

      expect(Osm::Email.send_email(
        api: $api,
        section: 1,
        to: { '2'=>{ 'firstname'=>'John', 'lastname'=>'Smith', 'emails'=>['john@example.com'] } },
        cc: 'cc@example.com',
        from: 'Sender <from@example.com>',
        subject: 'Subject of email',
        body: 'Body of email'
      )).to eq(true)
    end

    it 'Without cc' do
      expect($api).to receive(:post_query).with('ext/members/email/?action=send', post_data: {
        'sectionid' => 1,
        'emails' => '{"2":{"firstname":"John","lastname":"Smith","emails":["john@example.com"]}}',
        'scouts' => '2',
        'cc' => '',
        'from' => 'Sender <from@example.com>',
        'subject' => 'Subject of email',
        'body' => 'Body of email',
      }){ { 'ok'=>true } }

      expect(Osm::Email.send_email(
        api: $api,
        section: 1,
        to: { '2'=>{ 'firstname'=>'John', 'lastname'=>'Smith', 'emails'=>['john@example.com'] } },
        from: 'Sender <from@example.com>',
        subject: 'Subject of email',
        body: 'Body of email'
      )).to eq(true)
    end

    it 'To several members' do
      expect($api).to receive(:post_query).with('ext/members/email/?action=send', post_data: {
        'sectionid' => 1,
        'emails' => '{"2":{"firstname":"John","lastname":"Smith","emails":["john@example.com"]},"3":{"firstname":"Jane","lastname":"Smith","emails":["jane@example.com"]}}',
        'scouts' => '2,3',
        'cc' => '',
        'from' => 'Sender <from@example.com>',
        'subject' => 'Subject of email',
        'body' => 'Body of email',
      }){ { 'ok'=>true } }

      expect(Osm::Email.send_email(
        api: $api,
        section: 1,
        to: { '2'=>{ 'firstname'=>'John', 'lastname'=>'Smith', 'emails'=>['john@example.com'] },'3'=>{ 'firstname'=>'Jane', 'lastname'=>'Smith', 'emails'=>['jane@example.com'] } },
        from: 'Sender <from@example.com>',
        subject: 'Subject of email',
        body: 'Body of email'
      )).to eq(true)
    end

  end # describe Send email

end
