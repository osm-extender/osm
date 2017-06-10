describe Osm::Sms::DeliveryReport do

  it 'Create' do
    report = Osm::Sms::DeliveryReport.new(
      sms_id: 1,
      user_id: 2,
      member_id: 3,
      section_id: 4,
      from_name: 'a',
      from_number: '5',
      to_name: 'b',
      to_number: '6',
      message: 'c',
      scheduled: DateTime.new(2000, 1, 2, 3, 4, 5),
      last_updated: DateTime.new(2000, 1, 2, 3, 5, 6),
      credits: 7,
      status: :delivered,
    )

    expect(report.sms_id).to eq(1)
    expect(report.user_id).to eq(2)
    expect(report.member_id).to eq(3)
    expect(report.section_id).to eq(4)
    expect(report.from_name).to eq('a')
    expect(report.from_number).to eq('5')
    expect(report.to_name).to eq('b')
    expect(report.to_number).to eq('6')
    expect(report.message).to eq('c')
    expect(report.scheduled).to eq(DateTime.new(2000, 1, 2, 3, 4, 5))
    expect(report.last_updated).to eq(DateTime.new(2000, 1, 2, 3, 5, 6))
    expect(report.credits).to eq(7)
    expect(report.status).to eq(:delivered)
    expect(report.valid?).to eq(true)
  end # it create

  describe 'Status helpers' do
    statuses = [:sent, :not_sent, :delivered, :not_delivered, :invalid_destination_address, :invalid_source_address, :invalid_message_format, :route_not_available, :not_allowed]
    statuses.each do |status|
      it "For #{status}" do
        statuses.each do |test_status|
          expect(Osm::Sms::DeliveryReport.new(status: status).send("status_#{test_status}?")).to eq(status == test_status)
        end
      end
    end
  end # describe status helpers


  describe 'Using the OSM API' do

    it 'Get from OSM' do
      data = {
        'identifier' => 'smsid',
        'items' => [{
          'smsid' => '2',
          'userid' => '3',
          'scoutid' => '4',
          'sectionid' => '1',
          'phone' => '442345678901',
          'from' => 'From Name  443456789012',
          'message' => 'Test message.',
          'schedule' => '2000-01-02 03:04:05',
          'status' => 'DELIVERED',
          'lastupdated' => '2000-01-02 03:04:06',
          'credits' => '1',
          'fromuser' => 'From Name ',
          'firstname' => 'To',
          'lastname' => 'Name',
          'to' => 'To Name 441234567890'
        }]
      }
      expect($api).to receive(:post_query).with('sms.php?action=deliveryReports&sectionid=1&dateFormat=generic'){ data }

      reports = Osm::Sms::DeliveryReport.get_for_section(api: $api, section: 1)
      expect(reports.size).to eq(1)
      report = reports[0]
      expect(report.sms_id).to eq(2)
      expect(report.user_id).to eq(3)
      expect(report.member_id).to eq(4)
      expect(report.section_id).to eq(1)
      expect(report.from_name).to eq('From Name')
      expect(report.from_number).to eq('+443456789012')
      expect(report.to_name).to eq('To Name')
      expect(report.to_number).to eq('+441234567890')
      expect(report.message).to eq('Test message.')
      expect(report.scheduled).to eq(DateTime.new(2000, 1, 2, 3, 4, 5))
      expect(report.last_updated).to eq(DateTime.new(2000, 1, 2, 3, 4, 6))
      expect(report.credits).to eq(1)
      expect(report.status).to eq(:delivered)
    end

  end

end
