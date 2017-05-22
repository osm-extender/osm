# encoding: utf-8
require 'spec_helper'

describe "SMS" do

  describe "Send an SMS" do

    it "One person" do
      allow(Osm::Sms).to receive(:number_selected) { 2 }
      allow(Osm::Sms).to receive(:remaining_credits) { 3 }

      expect($api).to receive(:post_query).with('ext/members/sms/?action=sendText&sectionid=1', post_data: {
        'msg' => 'Test message.',
        'scouts' => '4',
        'source' => '441234567890',
        'type' => '',
      }){ {"result" => true, "msg" => "Message sent - you have <b>131<\/b> credits left.", "config" => {}} }

      result = Osm::Sms.send_sms(
        api:     $api,
        section: 1,
        members: 4,
        source_address: '441234567890',
        message: 'Test message.'
      )
      expect(result).to eq(true)
    end

    it "Several people" do
      allow(Osm::Sms).to receive(:number_selected) { 3 }
      allow(Osm::Sms).to receive(:remaining_credits) { 3 }

      expect($api).to receive(:post_query).with('ext/members/sms/?action=sendText&sectionid=1', post_data: {
        'msg' => 'This is a test message.',
        'scouts' => '2,3',
        'source' => '441234567890',
        'type' => '',
      }){ {"result" => true, "msg" => "Message sent - you have <b>95<\/b> credits left.", "config" => {}} }

      result = Osm::Sms.send_sms(
        api:     $api,
        section: 1,
        members: [2, 3],
        source_address: '441234567890',
        message: 'This is a test message.'
      )
      expect(result).to eq(true)
    end

    it "Failed" do
      allow(Osm::Sms).to receive(:number_selected) { 3 }
      allow(Osm::Sms).to receive(:remaining_credits) { 3 }

      expect($api).to receive(:post_query).with('ext/members/sms/?action=sendText&sectionid=1', post_data: {
        'msg' => 'Test message.',
        'scouts' => '4',
        'source' => '441234567890',
        'type' => '',
      }){ {"result" => false,"config" => {}} }

      result = Osm::Sms.send_sms(
        api:     $api,
        section: 1,
        members: [4],
        source_address: '441234567890',
        message: 'Test message.'
      )
      expect(result).to eq(false)
    end

    it "Raises error if not enough credits" do
      allow(Osm::Sms).to receive(:number_selected) { 3 }
      allow(Osm::Sms).to receive(:remaining_credits) { 2 }
      expect($api).not_to receive(:post_query)

      expect {
        Osm::Sms.send_sms(api: $api, section: 1, members: [2, 3], source_address: '441234567890', message: 'Test message.')
      }.to raise_error(Osm::Error, 'You do not have enough credits to send that message.')
    end

  end

  it "Gets remaining credits" do
    expect($api).to receive(:post_query).with('ext/members/sms/?action=getNumbers&sectionid=4&type=', post_data: {
      'scouts' => '0',
    }){ {"members" => 0, "numbers"=> 0, "sms_remaining" => 5} }

    expect(Osm::Sms.remaining_credits(api: $api, section: 4)).to eq(5)
  end

  it "Gets selected numbers" do
    expect($api).to receive(:post_query).with('ext/members/sms/?action=getNumbers&sectionid=4&type=', post_data: {
      'scouts' => '12,56',
    }){ {"members" => 2, "numbers" => 3, "sms_remaining" => 5} }

    expect(Osm::Sms.number_selected(api: $api, section: 4, members: [12, 56])).to eq(3)
  end


  describe "Delivery Report" do

    it "Create" do
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
    end

    describe "Status helpers" do
      statuses = Osm::Sms::DeliveryReport::VALID_STATUSES
      statuses.each do |status|
        it "For #{status}" do
          statuses.each do |test_status|
            expect(Osm::Sms::DeliveryReport.new(status: status).send("status_#{test_status}?")).to eq(status == test_status)
          end
        end
      end
    end

    it "Get from OSM" do
      data = {
        "identifier" => "smsid",
        "items" => [{
          "smsid" => "2",
          "userid" => "3",
          "scoutid" => "4",
          "sectionid" => "1",
          "phone" => "442345678901",
          "from" => "From Name  443456789012",
          "message" => "Test message.",
          "schedule" => "2000-01-02 03:04:05",
          "status" => "DELIVERED",
          "lastupdated" => "2000-01-02 03:04:06",
          "credits" => "1",
          "fromuser" => "From Name ",
          "firstname" => "To",
          "lastname" => "Name",
          "to" => "To Name 441234567890"
        }]
      }
      expect($api).to receive(:post_query).with("sms.php?action=deliveryReports&sectionid=1&dateFormat=generic"){ data }

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
