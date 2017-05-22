# encoding: utf-8
require 'spec_helper'

describe "SMS" do

  describe "Send an SMS" do

    it "One person" do
      Osm::Sms.stub(:number_selected) { 2 }
      Osm::Sms.stub(:remaining_credits) { 3 }

      $api.should_receive(:post_query).with('ext/members/sms/?action=sendText&sectionid=1', post_data: {
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
      result.should == true
    end

    it "Several people" do
      Osm::Sms.stub(:number_selected) { 3 }
      Osm::Sms.stub(:remaining_credits) { 3 }

      $api.should_receive(:post_query).with('ext/members/sms/?action=sendText&sectionid=1', post_data: {
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
      result.should == true
    end

    it "Failed" do
      Osm::Sms.stub(:number_selected) { 3 }
      Osm::Sms.stub(:remaining_credits) { 3 }

      $api.should_receive(:post_query).with('ext/members/sms/?action=sendText&sectionid=1', post_data: {
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
      result.should == false
    end

    it "Raises error if not enough credits" do
      Osm::Sms.stub(:number_selected) { 3 }
      Osm::Sms.stub(:remaining_credits) { 2 }
      $api.should_not_receive(:post_query)

      expect {
        Osm::Sms.send_sms(api: $api, section: 1, members: [2, 3], source_address: '441234567890', message: 'Test message.')
      }.to raise_error(Osm::Error, 'You do not have enough credits to send that message.')
    end

  end

  it "Gets remaining credits" do
    $api.should_receive(:post_query).with('ext/members/sms/?action=getNumbers&sectionid=4&type=', post_data: {
      'scouts' => '0',
    }){ {"members" => 0, "numbers"=> 0, "sms_remaining" => 5} }

    Osm::Sms.remaining_credits(api: $api, section: 4).should == 5
  end

  it "Gets selected numbers" do
    $api.should_receive(:post_query).with('ext/members/sms/?action=getNumbers&sectionid=4&type=', post_data: {
      'scouts' => '12,56',
    }){ {"members" => 2, "numbers" => 3, "sms_remaining" => 5} }

    Osm::Sms.number_selected(api: $api, section: 4, members: [12, 56]).should == 3
  end


  describe "Delivery Report" do

    it "Create" do
      report = Osm::Sms::DeliveryReport.new(
        :sms_id => 1,
        :user_id => 2,
        :member_id => 3,
        :section_id => 4,
        :from_name => 'a',
        :from_number => '5',
        :to_name => 'b',
        :to_number => '6',
        :message => 'c',
        :scheduled => DateTime.new(2000, 1, 2, 3, 4, 5),
        :last_updated => DateTime.new(2000, 1, 2, 3, 5, 6),
        :credits => 7,
        :status => :delivered,
      )

      report.sms_id.should == 1
      report.user_id.should == 2
      report.member_id.should == 3
      report.section_id.should == 4
      report.from_name.should == 'a'
      report.from_number.should == '5'
      report.to_name.should == 'b'
      report.to_number.should == '6'
      report.message.should == 'c'
      report.scheduled.should == DateTime.new(2000, 1, 2, 3, 4, 5)
      report.last_updated.should == DateTime.new(2000, 1, 2, 3, 5, 6)
      report.credits.should == 7
      report.status.should == :delivered
      report.valid?.should == true
    end

    describe "Status helpers" do
      statuses = Osm::Sms::DeliveryReport::VALID_STATUSES
      statuses.each do |status|
        it "For #{status}" do
          statuses.each do |test_status|
            Osm::Sms::DeliveryReport.new(:status => status).send("status_#{test_status}?").should == (status == test_status)
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
      $api.should_receive(:post_query).with("sms.php?action=deliveryReports&sectionid=1&dateFormat=generic"){ data }

      reports = Osm::Sms::DeliveryReport.get_for_section(api: $api, section: 1)
      reports.size.should == 1
      report = reports[0]
      report.sms_id.should == 2
      report.user_id.should == 3
      report.member_id.should == 4
      report.section_id.should == 1
      report.from_name.should == 'From Name'
      report.from_number.should == '+443456789012'
      report.to_name.should == 'To Name'
      report.to_number.should == '+441234567890'
      report.message.should == 'Test message.'
      report.scheduled.should == DateTime.new(2000, 1, 2, 3, 4, 5)
      report.last_updated.should == DateTime.new(2000, 1, 2, 3, 4, 6)
      report.credits.should == 1
      report.status.should == :delivered
    end

  end

end
