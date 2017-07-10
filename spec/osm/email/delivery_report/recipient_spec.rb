describe Osm::Email::DeliveryReport::Recipient do

  describe 'Attribute validity -' do

    before :each do
      @recipient = Osm::Email::DeliveryReport::Recipient.new(
        id:             1,
        member_id:      1,
        address:        'someone@example.com',
        delivery_report: Osm::Email::DeliveryReport.new,
        status:         :processed
      )
    end

    %w{id member_id}.each do |attribute|
      it attribute do
        @recipient.send("#{attribute}=", 0)
        expect(@recipient.valid?).to eq(false)
        expect(@recipient.errors.messages[attribute.to_sym]).to eq(['must be greater than 0'])
      end
    end

    it 'address' do
      @recipient.address = nil
      expect(@recipient.valid?).to eq(false)
      expect(@recipient.errors.messages[:address]).to eq(["can't be blank"])
    end

    describe 'status' do
      [nil, :invalid].each do |status|
        it "is #{status.inspect}" do
          @recipient.status = status
          expect(@recipient.valid?).to eq(false)
          expect(@recipient.errors.messages[:status]).to eq(['is not included in the list'])
        end
      end
    end

  end # describe Attribute validity


  it 'Fetch email from OSM' do
    email = Osm::Email::DeliveryReport::Email.new
    report = Osm::Email::DeliveryReport.new(id: 3, section_id: 4)
    recipient = Osm::Email::DeliveryReport::Recipient.new(member_id: 456, address: 'd@example.com', delivery_report: report)

    expect(Osm::Email::DeliveryReport::Email).to receive(:fetch_from_osm).with(api: $api, section: 4, email: 3, member: 456, address: 'd@example.com').and_return(email)
    expect(recipient.get_email($api)).to eq(email)
  end


  describe 'Unblock address in OSM' do
    it 'Success' do
      recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=unBlockEmail', post_data: { 'section_id' => 1, 'email' => 'a@example.com', 'email_id' => 2 }).and_return('status' => true)
      expect(recipient.unblock_address($api)).to eq(true)
    end

    it 'Fails with error message' do
      recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=unBlockEmail', post_data: { 'section_id' => 1, 'email' => 'a@example.com', 'email_id' => 2 }).and_return('status' => false, 'error' => 'Error message')
      expect { recipient.unblock_address($api) }.to raise_error(Osm::OSMError, 'Error message')
    end

    it 'Fails without error message' do
      recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=unBlockEmail', post_data: { 'section_id' => 1, 'email' => 'a@example.com', 'email_id' => 2 }).and_return('status' => false)
      expect(recipient.unblock_address($api)).to eq(false)
    end

    it 'Gets something other than a hash' do
      recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=unBlockEmail', post_data: { 'section_id' => 1, 'email' => 'a@example.com', 'email_id' => 2 }).and_return([])
      expect(recipient.unblock_address($api)).to eq(false)
    end

    describe "Doesn't try to unblock when status is" do

      before :each do
        @recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
        expect($api).not_to receive(:post_query)
      end

      (Osm::Email::DeliveryReport::VALID_STATUSES - [:bounced]).each do |status|
        it status do
          @recipient.status = status
          expect(@recipient.unblock_address($api)).to eq(true)
        end
      end # each status
    end

  end # describe unlock address in OSM


  describe 'Check status helpers -' do
    before :each do
      @processed_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :processed)
      @delivered_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :delivered)
      @bounced_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :bounced)
    end

    it 'processed?' do
      expect(@processed_recipient.processed?).to eq(true)
      expect(@delivered_recipient.processed?).to eq(false)
      expect(@bounced_recipient.processed?).to eq(false)
    end

    it 'delivered?' do
      expect(@processed_recipient.delivered?).to eq(false)
      expect(@delivered_recipient.delivered?).to eq(true)
      expect(@bounced_recipient.delivered?).to eq(false)
    end

    it 'bounced?' do
      expect(@processed_recipient.bounced?).to eq(false)
      expect(@delivered_recipient.bounced?).to eq(false)
      expect(@bounced_recipient.bounced?).to eq(true)
    end

  end # describe check status helpers


  it 'Converts to a string' do
    recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'recipient@example.com', status: :delivered)
    expect(recipient.to_s).to eq('recipient@example.com - delivered')
  end

  it 'Sorts by delivery_report then id' do
    report1 = Osm::Email::DeliveryReport.new(id: 1)
    report2 = Osm::Email::DeliveryReport.new(id: 2)

    recipient1 = Osm::Email::DeliveryReport::Recipient.new(delivery_report: report1, id: 1)
    recipient2 = Osm::Email::DeliveryReport::Recipient.new(delivery_report: report2, id: 1)
    recipient3 = Osm::Email::DeliveryReport::Recipient.new(delivery_report: report2, id: 2)

    recipients = [recipient3, recipient1, recipient2]
    expect(recipients.sort).to eq([recipient1, recipient2, recipient3])
  end

end
