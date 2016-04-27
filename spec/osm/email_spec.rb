# encoding: utf-8
require 'spec_helper'

describe "Email" do

  describe "DeliveryReport" do

    describe "Attribute validity -" do

      before :each do
        @report = Osm::Email::DeliveryReport.new(
          id:             1,
          section_id:     1,
          sent_at:        Time.new(2016, 10, 27, 13, 0),
          subject:        'Subject line of email',
          recipients:     [],
        )
      end

      %w{id section_id}.each do |attribute|
        it attribute do
          @report.send("#{attribute}=", 0)
          @report.valid?.should == false
          @report.errors.messages[attribute.to_sym].should == ["must be greater than 0"]
        end
      end

      %w{sent_at subject}.each do |attribute|
        it attribute do
          @report.send("#{attribute}=", nil)
          @report.valid?.should == false
          @report.errors.messages[attribute.to_sym].should == ["can't be blank"]
        end
      end

      describe "recipients" do

        it "Empty array allowed" do
          @report.recipients = []
          @report.valid?.should == true
          @report.errors.messages[:recipients].should == nil
        end

        it "Invalid item in array not allowed" do
          @report.recipients = [Osm::Email::DeliveryReport::Recipient.new()]
          @report.valid?.should == false
          @report.errors.messages[:recipients].should == ["contains an invalid item"]
        end

        it "Something other than a recipient not allowed" do
          @report.recipients = [Time.now]
          @report.valid?.should == false
          @report.errors.messages[:recipients].should == ["items in the Array must be a Osm::Email::DeliveryReport::Recipient"]
        end

      end # describe Email -> DeliveryReport : Invalid without : Recipients

    end # describe Email -> DeliveryReport : Invalid without


    it "Fetch delivery reports from OSM" do
      response = [
        {'id'=>"0", 'name'=>"ALL", 'type'=>"all", 'count'=>47},
        {'id'=>123, 'name'=>'01/02/2003 04:05 - Subject of email - 1', 'type'=>'email', 'parent'=>'0', 'hascontent'=>true, 'errors'=>0, 'opens'=>0, 'warnings'=>0},
        {'id'=>'123-1', 'name'=>'a@example.com - delivered', 'type'=>'oneEmail', 'status'=>'delivered', 'email'=>'a@example.com', 'email_key'=>'aexamplecom', 'hascontent'=>true, 'member_id'=>'12', 'parent'=>123, 'status_raw'=>'delivered'},
        {'id'=>'123-2', 'name'=>'b@example.com - processed', 'type'=>'oneEmail', 'status'=>'processed', 'email'=>'b@example.com', 'email_key'=>'bexamplecom', 'hascontent'=>true, 'member_id'=>'23', 'parent'=>123, 'status_raw'=>'processed'},
        {'id'=>'123-3', 'name'=>'c@example.com - bounced', 'type'=>'oneEmail', 'status'=>'bounced', 'email'=>'c@example.com', 'email_key'=>'cexamplecom', 'hascontent'=>true, 'member_id'=>'34', 'parent'=>123, 'status_raw'=>'bounced'},
      ]

      HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/ext/settings/emails/?action=getDeliveryReport&sectionid=1234', {:body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
      }}).once { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>response.to_json}) }

      reports = Osm::Email::DeliveryReport.get_for_section(@api, 1234)
      reports.count.should == 1
      report = reports[0]
      report.id.should == 123
      report.sent_at.should == Time.new(2003, 2, 1, 4, 5)
      report.subject.should == 'Subject of email - 1'
      report.section_id.should == 1234

      report.recipients.count.should == 3
      recipients = report.recipients.sort{ |a,b| a.id <=> b.id }
      recipients[0].delivery_report.should == report
      recipients[0].id.should == 1
      recipients[0].member_id.should == 12
      recipients[0].address.should == 'a@example.com'
      recipients[0].status.should == :delivered
      recipients[1].delivery_report.should == report
      recipients[1].id.should == 2
      recipients[1].member_id.should == 23
      recipients[1].address.should == 'b@example.com'
      recipients[1].status.should == :processed
      recipients[2].delivery_report.should == report
      recipients[2].id.should == 3
      recipients[2].member_id.should == 34
      recipients[2].address.should == 'c@example.com'
      recipients[2].status.should == :bounced
    end

    it "Fetch email from OSM" do
      email = Osm::Email::DeliveryReport::Email.new
      report = Osm::Email::DeliveryReport.new(id: 3, section_id: 4)

      Osm::Email::DeliveryReport::Email.should_receive(:fetch_from_osm).with(@api, 4, 3).once{ email }
      report.get_email(@api).should == email
    end

    describe "Get recipients of a certain status -" do

      before :each do
        @processed_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :processed)
        @delivered_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :delivered)
        @bounced_recipient   = Osm::Email::DeliveryReport::Recipient.new(status: :bounced)

        @reports = Osm::Email::DeliveryReport.new(recipients: [@processed_recipient, @delivered_recipient, @bounced_recipient])
      end

      %w{processed delivered bounced}.each do |status|
        it status do
          returned = @reports.send("#{status}_recipients")
          returned.should == [instance_variable_get("@#{status}_recipient")]
        end
      end

    end

    describe "Check for recipients of a certain status -" do

      before :each do
        @processed_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :processed)
        @delivered_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :delivered)
        @bounced_recipient   = Osm::Email::DeliveryReport::Recipient.new(status: :bounced)
      end

      %w{processed delivered bounced}.each do |status|
        it status do
          reports = Osm::Email::DeliveryReport.new(recipients: [instance_variable_get("@#{status}_recipient")])
          reports.send("#{status}_recipients?").should == true

          reports.recipients = []
          reports.send("#{status}_recipients?").should == false
        end
      end

    end

    it "Converts to a string" do
      report = Osm::Email::DeliveryReport.new(sent_at: Time.new(2016, 4, 17, 11, 50, 45), subject: 'Subject line of email')
      report.to_s.should == '17/04/2016 11:50 - Subject line of email'
    end

    it "Sorts by sent_at then id" do
      report1 = Osm::Email::DeliveryReport.new(sent_at: Time.new(2016), id: 1)
      report2 = Osm::Email::DeliveryReport.new(sent_at: Time.new(2017), id: 1)
      report3 = Osm::Email::DeliveryReport.new(sent_at: Time.new(2017), id: 2)
      reports = [report2, report3, report1]
      reports.sort.should == [report1, report2, report3]
    end


    describe "Recipient" do

      describe "Attribute validity -" do

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
            @recipient.valid?.should == false
            @recipient.errors.messages[attribute.to_sym].should == ["must be greater than 0"]
          end
        end

        it "address" do
          @recipient.address = nil
          @recipient.valid?.should == false
          @recipient.errors.messages[:address].should == ["can't be blank"]
        end

        describe "status" do
          [nil, :invalid].each do |status|
            it "is #{status.inspect}" do
              @recipient.status = status
              @recipient.valid?.should == false
              @recipient.errors.messages[:status].should == ["is not included in the list"]
            end
          end
        end

      end # describe Email -> DeliveryReport -> Recipient : invalid without
 
      it "Fetch email from OSM" do
        email = Osm::Email::DeliveryReport::Email.new
        report = Osm::Email::DeliveryReport.new(id: 3, section_id: 4)
        recipient = Osm::Email::DeliveryReport::Recipient.new(member_id: 456, address: 'd@example.com', delivery_report: report)

        Osm::Email::DeliveryReport::Email.should_receive(:fetch_from_osm).with(@api, 4, 3, 456, 'd@example.com').once{ email }
        recipient.get_email(@api).should == email
      end


      describe "Unblock address in OSM" do
        it "Success" do
          recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
          @api.should_receive(:perform_query).once.with('ext/settings/emails/?action=unBlockEmail', {"section_id"=>1, "email"=>"a@example.com", "email_id"=>2}){ {'status'=>true} }
          recipient.unblock_address(@api).should == true
        end

        it "Fails with error message" do
          recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
          @api.should_receive(:perform_query).once.with('ext/settings/emails/?action=unBlockEmail', {"section_id"=>1, "email"=>"a@example.com", "email_id"=>2}){ {'status'=>false, 'error'=>'Error message'} }
          expect{ recipient.unblock_address(@api) }.to raise_error(Osm::Error, 'Error message')
        end

        it "Fails without error message" do
          recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
          @api.should_receive(:perform_query).once.with('ext/settings/emails/?action=unBlockEmail', {"section_id"=>1, "email"=>"a@example.com", "email_id"=>2}){ {'status'=>false} }
          recipient.unblock_address(@api).should == false
        end

        it "Gets something other than a hash" do
          recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
          @api.should_receive(:perform_query).once.with('ext/settings/emails/?action=unBlockEmail', {"section_id"=>1, "email"=>"a@example.com", "email_id"=>2}){ [] }
          recipient.unblock_address(@api).should == false
        end

        describe "Doesn't try to unblock when status is" do

          before :each do
            @recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
            @api.should_not_receive(:perform_query)
          end

          (Osm::Email::DeliveryReport::VALID_STATUSES - [:bounced]).each do |status|
            it status do
              @recipient.status = status
              @recipient.unblock_address(@api).should == true
            end
          end # each status
        end

      end # unlock address in OSM

      describe "Check status helpers -" do
        before :each do
          @processed_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :processed)
          @delivered_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :delivered)
          @bounced_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :bounced)
        end

        it "processed?" do
          @processed_recipient.processed?.should == true
          @delivered_recipient.processed?.should == false
          @bounced_recipient.processed?.should == false
        end

        it "delivered?" do
          @processed_recipient.delivered?.should == false
          @delivered_recipient.delivered?.should == true
          @bounced_recipient.delivered?.should == false
        end

        it "bounced?" do
          @processed_recipient.bounced?.should == false
          @delivered_recipient.bounced?.should == false
          @bounced_recipient.bounced?.should == true
        end

      end

      it "Converts to a string" do
        recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'recipient@example.com', status: :delivered)
        recipient.to_s.should == 'recipient@example.com - delivered'
      end

      it "Sorts by delivery_report then id" do
        report1 = Osm::Email::DeliveryReport.new(id: 1)
        report2 = Osm::Email::DeliveryReport.new(id: 2)

        recipient1 = Osm::Email::DeliveryReport::Recipient.new(delivery_report: report1, id: 1)
        recipient2 = Osm::Email::DeliveryReport::Recipient.new(delivery_report: report2, id: 1)
        recipient3 = Osm::Email::DeliveryReport::Recipient.new(delivery_report: report2, id: 2)

        recipients = [recipient3, recipient1, recipient2]
        recipients.sort.should == [recipient1, recipient2, recipient3]
      end
 
    end # describe Email -> DeliveryReport -> Recipient

    describe "Email" do

      describe "Attribute validity -" do
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
            @email.valid?.should == false
            @email.errors.messages[attribute.to_sym].should == ["can't be blank"]
          end
        end
      end # describe Email -> DeliveryReport -> Email : invalid without

      it "Converts to a string" do
        email = Osm::Email::DeliveryReport::Email.new(
          to:       'to@example.com',
          from:     '"Sender" <from@example.com>',
          subject:  'What the email is about',
          body:     '<p>Hello person.</p>'
        )
        email.to_s.should == "To: to@example.com\nFrom: \"Sender\" <from@example.com>\n\nWhat the email is about\n\nHello person."
      end

      it "Sorts by subject then from then to" do
        email1 = Osm::Email::DeliveryReport::Email.new(subject: 'a', from: 'a', to: 'a')
        email2 = Osm::Email::DeliveryReport::Email.new(subject: 'b', from: 'a', to: 'a')
        email3 = Osm::Email::DeliveryReport::Email.new(subject: 'b', from: 'b', to: 'a')
        email4 = Osm::Email::DeliveryReport::Email.new(subject: 'b', from: 'b', to: 'b')

        emails = [email2, email3, email4, email1]
        emails.sort.should == [email1, email2, email3, email4]
      end

      describe "Fetch email from OSM" do

        it "For a delivery report" do
          @api.should_receive(:perform_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').once{ {'data'=>{'to'=>'1 Recipient', 'from'=>'"From" <from@example.com>', 'subject'=>'Subject of email', 'sent'=>'16/04/2016 13:45'}, 'status'=>true, 'error'=>nil, 'meta'=>[]} }
          @api.should_receive(:perform_query).with('ext/settings/emails/?action=getSentEmailContent&section_id=1&email_id=2&email=&member_id=', {}, true).once{ 'This is the body of the email.' }

          email = Osm::Email::DeliveryReport::Email.fetch_from_osm(@api, 1, 2)
          email.to.should == '1 Recipient'
          email.from.should == '"From" <from@example.com>'
          email.subject.should == 'Subject of email'
          email.body.should == 'This is the body of the email.'
        end

        it "For a recipient" do
          @api.should_receive(:perform_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=to@example.com&member_id=3').once{ {'data'=>{'to'=>'to@example.com', 'from'=>'"From" <from@example.com>', 'subject'=>'Subject of email', 'sent'=>'16/04/2016 13:45'}, 'status'=>true, 'error'=>nil, 'meta'=>[]} }
          @api.should_receive(:perform_query).with('ext/settings/emails/?action=getSentEmailContent&section_id=1&email_id=2&email=to@example.com&member_id=3', {}, true).once{ 'This is the body of the email.' }

          email = Osm::Email::DeliveryReport::Email.fetch_from_osm(@api, 1, 2, 3, 'to@example.com')
          email.to.should == 'to@example.com'
          email.from.should == '"From" <from@example.com>'
          email.subject.should == 'Subject of email'
          email.body.should == 'This is the body of the email.'
        end

        describe "Error getting meta data" do

          it "Didn't get a Hash" do
            @api.should_receive(:perform_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').once{ nil }
            expect{ Osm::Email::DeliveryReport::Email.fetch_from_osm(@api, 1, 2) }.to raise_error Osm::Error, 'Unexpected format for response - got a NilClass'
          end

          it "Got an error from OSM" do
            @api.should_receive(:perform_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').once{ {'success'=>false, 'error'=>'Error message'} }
            expect{ Osm::Email::DeliveryReport::Email.fetch_from_osm(@api, 1, 2) }.to raise_error Osm::Error, 'Error message'
          end

        end

        it "Error getting body" do
          @api.should_receive(:perform_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').once{ {'data'=>{'to'=>'1 Recipient', 'from'=>'"From" <from@example.com>', 'subject'=>'Subject of email', 'sent'=>'16/04/2016 13:45'}, 'status'=>true, 'error'=>nil, 'meta'=>[]} }
          @api.should_receive(:perform_query).with('ext/settings/emails/?action=getSentEmailContent&section_id=1&email_id=2&email=&member_id=', {}, true).once{ raise Osm::Forbidden, 'Email not found' }
          expect{ Osm::Email::DeliveryReport::Email.fetch_from_osm(@api, 1, 2) }.to raise_error Osm::Error, 'Email not found'
        end

      end # describe Email -> DeliveryReport -> Email : fetch email from osm

    end # describe Email -> DeliveryReport -> Email

  end # describe Email -> DeliveryReport

end
