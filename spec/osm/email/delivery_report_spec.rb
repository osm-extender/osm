describe OSM::Email::DeliveryReport do

  describe 'Attribute validity -' do

    before :each do
      @report = OSM::Email::DeliveryReport.new(
        id:             1,
        section_id:     1,
        sent_at:        Time.new(2016, 10, 27, 13, 0),
        subject:        'Subject line of email',
        recipients:     []
      )
    end

    %w{id section_id}.each do |attribute|
      it attribute do
        @report.send("#{attribute}=", 0)
        expect(@report.valid?).to eq(false)
        expect(@report.errors.messages[attribute.to_sym]).to eq(['must be greater than 0'])
      end
    end

    %w{sent_at subject}.each do |attribute|
      it attribute do
        @report.send("#{attribute}=", nil)
        expect(@report.valid?).to eq(false)
        expect(@report.errors.messages[attribute.to_sym]).to eq(["can't be blank"])
      end
    end

    describe 'recipients' do

      it 'Empty array allowed' do
        @report.recipients = []
        expect(@report.valid?).to eq(true)
        expect(@report.errors.messages[:recipients]).to eq(nil)
      end

      it 'Invalid item in array not allowed' do
        @report.recipients = [OSM::Email::DeliveryReport::Recipient.new()]
        expect(@report.valid?).to eq(false)
        expect(@report.errors.messages[:recipients]).to eq(['contains an invalid item'])
      end

      it 'Something other than a recipient not allowed' do
        @report.recipients = [Time.now]
        expect(@report.valid?).to eq(false)
        expect(@report.errors.messages[:recipients]).to eq(['items in the Array must be a OSM::Email::DeliveryReport::Recipient'])
      end

    end # describe recipients

  end # describe Attribute validity


  it 'Fetch delivery reports from OSM' do
    expect($api).to receive(:post_query).with('ext/settings/emails/?action=getDeliveryReport&sectionid=1234').and_return([
      { 'id' => '0', 'name' => 'ALL', 'type' => 'all', 'count' => 47 },
      { 'id' => 123, 'name' => '01/02/2003 04:05 - Subject of email - 1', 'type' => 'email', 'parent' => '0', 'hascontent' => true, 'errors' => 0, 'opens' => 0, 'warnings' => 0 },
      { 'id' => '123-1', 'name' => 'a@example.com - delivered', 'type' => 'oneEmail', 'status' => 'delivered', 'email' => 'a@example.com', 'email_key' => 'aexamplecom', 'hascontent' => true, 'member_id' => '12', 'parent' => 123, 'status_raw' => 'delivered' },
      { 'id' => '123-2', 'name' => 'b@example.com - processed', 'type' => 'oneEmail', 'status' => 'processed', 'email' => 'b@example.com', 'email_key' => 'bexamplecom', 'hascontent' => true, 'member_id' => '23', 'parent' => 123, 'status_raw' => 'processed' },
      { 'id' => '123-3', 'name' => 'c@example.com - bounced', 'type' => 'oneEmail', 'status' => 'bounced', 'email' => 'c@example.com', 'email_key' => 'cexamplecom', 'hascontent' => true, 'member_id' => '34', 'parent' => 123, 'status_raw' => 'bounced' }
    ])

    reports = OSM::Email::DeliveryReport.get_for_section(api: $api, section: 1234)
    expect(reports.count).to eq(1)
    report = reports[0]
    expect(report.id).to eq(123)
    expect(report.sent_at).to eq(Time.new(2003, 2, 1, 4, 5))
    expect(report.subject).to eq('Subject of email - 1')
    expect(report.section_id).to eq(1234)

    expect(report.recipients.count).to eq(3)
    recipients = report.recipients.sort { |a, b| a.id <=> b.id }
    expect(recipients[0].delivery_report).to eq(report)
    expect(recipients[0].id).to eq(1)
    expect(recipients[0].member_id).to eq(12)
    expect(recipients[0].address).to eq('a@example.com')
    expect(recipients[0].status).to eq(:delivered)
    expect(recipients[1].delivery_report).to eq(report)
    expect(recipients[1].id).to eq(2)
    expect(recipients[1].member_id).to eq(23)
    expect(recipients[1].address).to eq('b@example.com')
    expect(recipients[1].status).to eq(:processed)
    expect(recipients[2].delivery_report).to eq(report)
    expect(recipients[2].id).to eq(3)
    expect(recipients[2].member_id).to eq(34)
    expect(recipients[2].address).to eq('c@example.com')
    expect(recipients[2].status).to eq(:bounced)
  end

  it 'Fetch email from OSM' do
    email = OSM::Email::DeliveryReport::Email.new
    report = OSM::Email::DeliveryReport.new(id: 3, section_id: 4)

    expect(OSM::Email::DeliveryReport::Email).to receive(:fetch_from_osm).with(api: $api, section: 4, email: 3).and_return(email)
    expect(report.get_email($api)).to eq(email)
  end

  describe 'Get recipients of a certain status -' do
    before :each do
      @processed_recipient = OSM::Email::DeliveryReport::Recipient.new(status: :processed)
      @delivered_recipient = OSM::Email::DeliveryReport::Recipient.new(status: :delivered)
      @bounced_recipient   = OSM::Email::DeliveryReport::Recipient.new(status: :bounced)
      @reports = OSM::Email::DeliveryReport.new(recipients: [@processed_recipient, @delivered_recipient, @bounced_recipient])
    end
    %w{processed delivered bounced}.each do |status|
      it status do
        returned = @reports.send("#{status}_recipients")
        expect(returned).to eq([instance_variable_get("@#{status}_recipient")])
      end
    end
  end # describe Get recipients of a certain status

  describe 'Check for recipients of a certain status -' do
    before :each do
      @processed_recipient = OSM::Email::DeliveryReport::Recipient.new(status: :processed)
      @delivered_recipient = OSM::Email::DeliveryReport::Recipient.new(status: :delivered)
      @bounced_recipient   = OSM::Email::DeliveryReport::Recipient.new(status: :bounced)
    end
    %w{processed delivered bounced}.each do |status|
      it status do
        reports = OSM::Email::DeliveryReport.new(recipients: [instance_variable_get("@#{status}_recipient")])
        expect(reports.send("#{status}_recipients?")).to eq(true)
        reports.recipients = []
        expect(reports.send("#{status}_recipients?")).to eq(false)
      end
    end
  end # describe Check for recipients of a certain status

  it 'Converts to a string' do
    report = OSM::Email::DeliveryReport.new(sent_at: Time.new(2016, 4, 17, 11, 50, 45), subject: 'Subject line of email')
    expect(report.to_s).to eq('17/04/2016 11:50 - Subject line of email')
  end

  it 'Sorts by sent_at then id' do
    report1 = OSM::Email::DeliveryReport.new(sent_at: Time.new(2016), id: 1)
    report2 = OSM::Email::DeliveryReport.new(sent_at: Time.new(2017), id: 1)
    report3 = OSM::Email::DeliveryReport.new(sent_at: Time.new(2017), id: 2)
    reports = [report2, report3, report1]
    expect(reports.sort).to eq([report1, report2, report3])
  end

end
