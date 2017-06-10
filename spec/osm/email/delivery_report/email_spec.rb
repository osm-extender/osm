describe Osm::Email::DeliveryReport::Email do

  describe 'Attribute validity -' do
    before :each do
      @email = Osm::Email::DeliveryReport::Email.new(
        to:       'to@example.com',
        from:     'from@example.com',
        subject:  'Subject of email',
        body:     'Body of email message.',
      )
    end
    %w{to from subject body}.each do |attribute|
      it attribute do
        @email.send("#{attribute}=", nil)
        expect(@email.valid?).to eq(false)
        expect(@email.errors.messages[attribute.to_sym]).to eq(["can't be blank"])
      end
    end
  end # describe attribute validity


  it 'Converts to a string' do
    email = Osm::Email::DeliveryReport::Email.new(
      to:       'to@example.com',
      from:     '"Sender" <from@example.com>',
      subject:  'What the email is about',
      body:     '<p>Hello person.</p>'
    )
    expect(email.to_s).to eq("To: to@example.com\nFrom: \"Sender\" <from@example.com>\n\nWhat the email is about\n\nHello person.")
  end

  it 'Sorts by subject then from then to' do
    email1 = Osm::Email::DeliveryReport::Email.new(subject: 'a', from: 'a', to: 'a')
    email2 = Osm::Email::DeliveryReport::Email.new(subject: 'b', from: 'a', to: 'a')
    email3 = Osm::Email::DeliveryReport::Email.new(subject: 'b', from: 'b', to: 'a')
    email4 = Osm::Email::DeliveryReport::Email.new(subject: 'b', from: 'b', to: 'b')

    emails = [email2, email3, email4, email1]
    expect(emails.sort).to eq([email1, email2, email3, email4])
  end


  describe 'Fetch email from OSM' do

    it 'For a delivery report' do
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').and_return('data'=>{ 'to'=>'1 Recipient', 'from'=>'"From" <from@example.com>', 'subject'=>'Subject of email', 'sent'=>'16/04/2016 13:45' }, 'status'=>true, 'error'=>nil, 'meta'=>[])
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmailContent&section_id=1&email_id=2&email=&member_id=').and_return('This is the body of the email.')

      email = Osm::Email::DeliveryReport::Email.fetch_from_osm(api: $api, section: 1, email: 2)
      expect(email.to).to eq('1 Recipient')
      expect(email.from).to eq('"From" <from@example.com>')
      expect(email.subject).to eq('Subject of email')
      expect(email.body).to eq('This is the body of the email.')
    end

    it 'For a recipient' do
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=to@example.com&member_id=3').and_return('data'=>{ 'to'=>'to@example.com', 'from'=>'"From" <from@example.com>', 'subject'=>'Subject of email', 'sent'=>'16/04/2016 13:45' }, 'status'=>true, 'error'=>nil, 'meta'=>[])
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmailContent&section_id=1&email_id=2&email=to@example.com&member_id=3').and_return('This is the body of the email.')

      email = Osm::Email::DeliveryReport::Email.fetch_from_osm(api: $api, section: 1, email: 2, member: 3, address: 'to@example.com')
      expect(email.to).to eq('to@example.com')
      expect(email.from).to eq('"From" <from@example.com>')
      expect(email.subject).to eq('Subject of email')
      expect(email.body).to eq('This is the body of the email.')
    end

    describe 'Error getting meta data' do

      it "Didn't get a Hash" do
        expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').and_return(nil)
        expect{ Osm::Email::DeliveryReport::Email.fetch_from_osm(api: $api, section: 1, email: 2) }.to raise_error Osm::Error, 'Unexpected format for response - got a NilClass'
      end

      it 'Got an error from OSM' do
        expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').and_return('success'=>false, 'error'=>'Error message')
        expect{ Osm::Email::DeliveryReport::Email.fetch_from_osm(api: $api, section: 1, email: 2) }.to raise_error Osm::Error, 'Error message'
      end

    end # describe Error getting meta data

    it 'Error getting body' do
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').and_return('data'=>{ 'to'=>'1 Recipient', 'from'=>'"From" <from@example.com>', 'subject'=>'Subject of email', 'sent'=>'16/04/2016 13:45' }, 'status'=>true, 'error'=>nil, 'meta'=>[])
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmailContent&section_id=1&email_id=2&email=&member_id=').once{ raise Osm::Forbidden, 'Email not found' }
      expect{ Osm::Email::DeliveryReport::Email.fetch_from_osm(api: $api, section: 1, email: 2) }.to raise_error Osm::Error, 'Email not found'
    end

  end # describe Fetch email from OSM

end
