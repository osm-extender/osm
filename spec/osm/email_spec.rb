# encoding: utf-8
require 'spec_helper'

describe "Email" do

  describe "Get emails for contacts" do

    it "Single member" do
      expect($api).to receive(:post_query).with("/ext/members/email/?action=getSelectedEmailsFromContacts&sectionid=1&scouts=2", post_data: {"contactGroups" => '["contact_primary_member"]'}).and_return({
        "emails"=>{
          "2"=>{
            "emails"=>["john@example.com"],
            "firstname"=>"John",
            "lastname"=>"Smith"
          }
        },
        "count"=>1
      })

      result = Osm::Email.get_emails_for_contacts(api: $api, section: 1, contacts: :member, members: 2)
      expect(result).to eq({
        '2' => {
          'emails' => ['john@example.com'],
          'firstname' => 'John',
          'lastname' => 'Smith'
        }
      })
    end

    it "Several members" do
      expect($api).to receive(:post_query).with("/ext/members/email/?action=getSelectedEmailsFromContacts&sectionid=1&scouts=2,3", post_data: {"contactGroups" => '["contact_primary_member"]'}).and_return({
        "emails"=>{
          "2"=>{
            "emails"=>["john@example.com"],
            "firstname"=>"John",
            "lastname"=>"Smith"
          },
          "3"=>{
            "emails"=>["jane@example.com","jane2@example.com"],
            "firstname"=>"Jane",
            "lastname"=>"Smith"
          }
        },
        "count"=>3
      })

      result = Osm::Email.get_emails_for_contacts(api: $api, section: 1, contacts: :member, members: [2,3])
      expect(result).to eq({
        '2' => {
          'emails' => ['john@example.com'],
          'firstname' => 'John',
          'lastname' => 'Smith'
        },
        '3' => {
          'emails' => ['jane@example.com', 'jane2@example.com'],
          'firstname' => 'Jane',
          'lastname' => 'Smith'
        }
      })
    end

    it "Requires at least one contact" do
      expect($api).not_to receive(:post_query)
      expect{ Osm::Email.get_emails_for_contacts(api: $api, section: 1, contacts: [], members: [2]) }.to raise_error ArgumentError, "You must pass at least one contact"
    end

    it "Checks for invalid contacts" do
      expect($api).not_to receive(:post_query)
      expect{ Osm::Email.get_emails_for_contacts(api: $api, section: 1, contacts: [:invalid_contact], members: [2]) }.to raise_error ArgumentError, "Invalid contact - :invalid_contact"
    end

    it "Requires at least one member" do
      expect($api).not_to receive(:post_query)
      expect{ Osm::Email.get_emails_for_contacts(api: $api, section: 1, contacts: [:primary], members: []) }.to raise_error ArgumentError, "You must pass at least one member"
    end

  end # describe Get emails for conatcts

  describe "Send email" do

    it "With cc" do
      expect($api).to receive(:post_query).with("ext/members/email/?action=send", post_data: {
        'sectionid' => 1,
        'emails' => '{"2":{"firstname":"John","lastname":"Smith","emails":["john@example.com"]}}',
        'scouts' => '2',
        'cc' => 'cc@example.com',
        'from' => 'Sender <from@example.com>',
        'subject' => 'Subject of email',
        'body' => 'Body of email',
      }){ {'ok'=>true} }

      expect(Osm::Email.send_email(
        api: $api,
        section: 1,
        to: {'2'=>{'firstname'=>'John', 'lastname'=>'Smith', 'emails'=>['john@example.com']}},
        cc: 'cc@example.com',
        from: 'Sender <from@example.com>',
        subject: 'Subject of email',
        body: 'Body of email',
      )).to eq(true)
    end

    it "Without cc" do
      expect($api).to receive(:post_query).with("ext/members/email/?action=send", post_data: {
        'sectionid' => 1,
        'emails' => '{"2":{"firstname":"John","lastname":"Smith","emails":["john@example.com"]}}',
        'scouts' => '2',
        'cc' => '',
        'from' => 'Sender <from@example.com>',
        'subject' => 'Subject of email',
        'body' => 'Body of email',
      }){ {'ok'=>true} }

      expect(Osm::Email.send_email(
        api: $api,
        section: 1,
        to: {'2'=>{'firstname'=>'John', 'lastname'=>'Smith', 'emails'=>['john@example.com']}},
        from: 'Sender <from@example.com>',
        subject: 'Subject of email',
        body: 'Body of email',
      )).to eq(true)
    end

    it "To several members" do
      expect($api).to receive(:post_query).with("ext/members/email/?action=send", post_data: {
        'sectionid' => 1,
        'emails' => '{"2":{"firstname":"John","lastname":"Smith","emails":["john@example.com"]},"3":{"firstname":"Jane","lastname":"Smith","emails":["jane@example.com"]}}',
        'scouts' => '2,3',
        'cc' => '',
        'from' => 'Sender <from@example.com>',
        'subject' => 'Subject of email',
        'body' => 'Body of email',
      }){ {'ok'=>true} }

      expect(Osm::Email.send_email(
        api: $api,
        section: 1,
        to: {'2'=>{'firstname'=>'John', 'lastname'=>'Smith', 'emails'=>['john@example.com']},'3'=>{'firstname'=>'Jane', 'lastname'=>'Smith', 'emails'=>['jane@example.com']}},
        from: 'Sender <from@example.com>',
        subject: 'Subject of email',
        body: 'Body of email',
      )).to eq(true)
    end

  end # describe Send email


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
          expect(@report.valid?).to eq(false)
          expect(@report.errors.messages[attribute.to_sym]).to eq(["must be greater than 0"])
        end
      end

      %w{sent_at subject}.each do |attribute|
        it attribute do
          @report.send("#{attribute}=", nil)
          expect(@report.valid?).to eq(false)
          expect(@report.errors.messages[attribute.to_sym]).to eq(["can't be blank"])
        end
      end

      describe "recipients" do

        it "Empty array allowed" do
          @report.recipients = []
          expect(@report.valid?).to eq(true)
          expect(@report.errors.messages[:recipients]).to eq(nil)
        end

        it "Invalid item in array not allowed" do
          @report.recipients = [Osm::Email::DeliveryReport::Recipient.new()]
          expect(@report.valid?).to eq(false)
          expect(@report.errors.messages[:recipients]).to eq(["contains an invalid item"])
        end

        it "Something other than a recipient not allowed" do
          @report.recipients = [Time.now]
          expect(@report.valid?).to eq(false)
          expect(@report.errors.messages[:recipients]).to eq(["items in the Array must be a Osm::Email::DeliveryReport::Recipient"])
        end

      end # describe Email -> DeliveryReport : Invalid without : Recipients

    end # describe Email -> DeliveryReport : Invalid without


    it "Fetch delivery reports from OSM" do
      expect($api).to receive(:post_query).with('ext/settings/emails/?action=getDeliveryReport&sectionid=1234').and_return([
        {'id'=>"0", 'name'=>"ALL", 'type'=>"all", 'count'=>47},
        {'id'=>123, 'name'=>'01/02/2003 04:05 - Subject of email - 1', 'type'=>'email', 'parent'=>'0', 'hascontent'=>true, 'errors'=>0, 'opens'=>0, 'warnings'=>0},
        {'id'=>'123-1', 'name'=>'a@example.com - delivered', 'type'=>'oneEmail', 'status'=>'delivered', 'email'=>'a@example.com', 'email_key'=>'aexamplecom', 'hascontent'=>true, 'member_id'=>'12', 'parent'=>123, 'status_raw'=>'delivered'},
        {'id'=>'123-2', 'name'=>'b@example.com - processed', 'type'=>'oneEmail', 'status'=>'processed', 'email'=>'b@example.com', 'email_key'=>'bexamplecom', 'hascontent'=>true, 'member_id'=>'23', 'parent'=>123, 'status_raw'=>'processed'},
        {'id'=>'123-3', 'name'=>'c@example.com - bounced', 'type'=>'oneEmail', 'status'=>'bounced', 'email'=>'c@example.com', 'email_key'=>'cexamplecom', 'hascontent'=>true, 'member_id'=>'34', 'parent'=>123, 'status_raw'=>'bounced'},
      ])

      reports = Osm::Email::DeliveryReport.get_for_section(api: $api, section: 1234)
      expect(reports.count).to eq(1)
      report = reports[0]
      expect(report.id).to eq(123)
      expect(report.sent_at).to eq(Time.new(2003, 2, 1, 4, 5))
      expect(report.subject).to eq('Subject of email - 1')
      expect(report.section_id).to eq(1234)

      expect(report.recipients.count).to eq(3)
      recipients = report.recipients.sort{ |a,b| a.id <=> b.id }
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

    it "Fetch email from OSM" do
      email = Osm::Email::DeliveryReport::Email.new
      report = Osm::Email::DeliveryReport.new(id: 3, section_id: 4)

      expect(Osm::Email::DeliveryReport::Email).to receive(:fetch_from_osm).with(api: $api, section: 4, email: 3).and_return(email)
      expect(report.get_email($api)).to eq(email)
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
          expect(returned).to eq([instance_variable_get("@#{status}_recipient")])
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
          expect(reports.send("#{status}_recipients?")).to eq(true)

          reports.recipients = []
          expect(reports.send("#{status}_recipients?")).to eq(false)
        end
      end

    end

    it "Converts to a string" do
      report = Osm::Email::DeliveryReport.new(sent_at: Time.new(2016, 4, 17, 11, 50, 45), subject: 'Subject line of email')
      expect(report.to_s).to eq('17/04/2016 11:50 - Subject line of email')
    end

    it "Sorts by sent_at then id" do
      report1 = Osm::Email::DeliveryReport.new(sent_at: Time.new(2016), id: 1)
      report2 = Osm::Email::DeliveryReport.new(sent_at: Time.new(2017), id: 1)
      report3 = Osm::Email::DeliveryReport.new(sent_at: Time.new(2017), id: 2)
      reports = [report2, report3, report1]
      expect(reports.sort).to eq([report1, report2, report3])
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
            expect(@recipient.valid?).to eq(false)
            expect(@recipient.errors.messages[attribute.to_sym]).to eq(["must be greater than 0"])
          end
        end

        it "address" do
          @recipient.address = nil
          expect(@recipient.valid?).to eq(false)
          expect(@recipient.errors.messages[:address]).to eq(["can't be blank"])
        end

        describe "status" do
          [nil, :invalid].each do |status|
            it "is #{status.inspect}" do
              @recipient.status = status
              expect(@recipient.valid?).to eq(false)
              expect(@recipient.errors.messages[:status]).to eq(["is not included in the list"])
            end
          end
        end

      end # describe Email -> DeliveryReport -> Recipient : invalid without
 
      it "Fetch email from OSM" do
        email = Osm::Email::DeliveryReport::Email.new
        report = Osm::Email::DeliveryReport.new(id: 3, section_id: 4)
        recipient = Osm::Email::DeliveryReport::Recipient.new(member_id: 456, address: 'd@example.com', delivery_report: report)

        expect(Osm::Email::DeliveryReport::Email).to receive(:fetch_from_osm).with(api: $api, section: 4, email: 3, member: 456, address: 'd@example.com').and_return(email)
        expect(recipient.get_email($api)).to eq(email)
      end


      describe "Unblock address in OSM" do
        it "Success" do
          recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
          expect($api).to receive(:post_query).with('ext/settings/emails/?action=unBlockEmail', post_data: {"section_id"=>1, "email"=>"a@example.com", "email_id"=>2}).and_return({'status'=>true})
          expect(recipient.unblock_address($api)).to eq(true)
        end

        it "Fails with error message" do
          recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
          expect($api).to receive(:post_query).with('ext/settings/emails/?action=unBlockEmail', post_data: {"section_id"=>1, "email"=>"a@example.com", "email_id"=>2}).and_return({'status'=>false, 'error'=>'Error message'})
          expect{ recipient.unblock_address($api) }.to raise_error(Osm::Error, 'Error message')
        end

        it "Fails without error message" do
          recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
          expect($api).to receive(:post_query).with('ext/settings/emails/?action=unBlockEmail', post_data: {"section_id"=>1, "email"=>"a@example.com", "email_id"=>2}).and_return({'status'=>false})
          expect(recipient.unblock_address($api)).to eq(false)
        end

        it "Gets something other than a hash" do
          recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'a@example.com', status: :bounced, delivery_report: Osm::Email::DeliveryReport.new(id: 2, section_id: 1))
          expect($api).to receive(:post_query).with('ext/settings/emails/?action=unBlockEmail', post_data: {"section_id"=>1, "email"=>"a@example.com", "email_id"=>2}).and_return([])
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

      end # unlock address in OSM

      describe "Check status helpers -" do
        before :each do
          @processed_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :processed)
          @delivered_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :delivered)
          @bounced_recipient = Osm::Email::DeliveryReport::Recipient.new(status: :bounced)
        end

        it "processed?" do
          expect(@processed_recipient.processed?).to eq(true)
          expect(@delivered_recipient.processed?).to eq(false)
          expect(@bounced_recipient.processed?).to eq(false)
        end

        it "delivered?" do
          expect(@processed_recipient.delivered?).to eq(false)
          expect(@delivered_recipient.delivered?).to eq(true)
          expect(@bounced_recipient.delivered?).to eq(false)
        end

        it "bounced?" do
          expect(@processed_recipient.bounced?).to eq(false)
          expect(@delivered_recipient.bounced?).to eq(false)
          expect(@bounced_recipient.bounced?).to eq(true)
        end

      end

      it "Converts to a string" do
        recipient = Osm::Email::DeliveryReport::Recipient.new(address: 'recipient@example.com', status: :delivered)
        expect(recipient.to_s).to eq('recipient@example.com - delivered')
      end

      it "Sorts by delivery_report then id" do
        report1 = Osm::Email::DeliveryReport.new(id: 1)
        report2 = Osm::Email::DeliveryReport.new(id: 2)

        recipient1 = Osm::Email::DeliveryReport::Recipient.new(delivery_report: report1, id: 1)
        recipient2 = Osm::Email::DeliveryReport::Recipient.new(delivery_report: report2, id: 1)
        recipient3 = Osm::Email::DeliveryReport::Recipient.new(delivery_report: report2, id: 2)

        recipients = [recipient3, recipient1, recipient2]
        expect(recipients.sort).to eq([recipient1, recipient2, recipient3])
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
            expect(@email.valid?).to eq(false)
            expect(@email.errors.messages[attribute.to_sym]).to eq(["can't be blank"])
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
        expect(email.to_s).to eq("To: to@example.com\nFrom: \"Sender\" <from@example.com>\n\nWhat the email is about\n\nHello person.")
      end

      it "Sorts by subject then from then to" do
        email1 = Osm::Email::DeliveryReport::Email.new(subject: 'a', from: 'a', to: 'a')
        email2 = Osm::Email::DeliveryReport::Email.new(subject: 'b', from: 'a', to: 'a')
        email3 = Osm::Email::DeliveryReport::Email.new(subject: 'b', from: 'b', to: 'a')
        email4 = Osm::Email::DeliveryReport::Email.new(subject: 'b', from: 'b', to: 'b')

        emails = [email2, email3, email4, email1]
        expect(emails.sort).to eq([email1, email2, email3, email4])
      end

      describe "Fetch email from OSM" do

        it "For a delivery report" do
          expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').and_return({'data'=>{'to'=>'1 Recipient', 'from'=>'"From" <from@example.com>', 'subject'=>'Subject of email', 'sent'=>'16/04/2016 13:45'}, 'status'=>true, 'error'=>nil, 'meta'=>[]})
          expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmailContent&section_id=1&email_id=2&email=&member_id=').and_return('This is the body of the email.')

          email = Osm::Email::DeliveryReport::Email.fetch_from_osm(api: $api, section: 1, email: 2)
          expect(email.to).to eq('1 Recipient')
          expect(email.from).to eq('"From" <from@example.com>')
          expect(email.subject).to eq('Subject of email')
          expect(email.body).to eq('This is the body of the email.')
        end

        it "For a recipient" do
          expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=to@example.com&member_id=3').and_return({'data'=>{'to'=>'to@example.com', 'from'=>'"From" <from@example.com>', 'subject'=>'Subject of email', 'sent'=>'16/04/2016 13:45'}, 'status'=>true, 'error'=>nil, 'meta'=>[]})
          expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmailContent&section_id=1&email_id=2&email=to@example.com&member_id=3').and_return('This is the body of the email.')

          email = Osm::Email::DeliveryReport::Email.fetch_from_osm(api: $api, section: 1, email: 2, member: 3, address: 'to@example.com')
          expect(email.to).to eq('to@example.com')
          expect(email.from).to eq('"From" <from@example.com>')
          expect(email.subject).to eq('Subject of email')
          expect(email.body).to eq('This is the body of the email.')
        end

        describe "Error getting meta data" do

          it "Didn't get a Hash" do
            expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').and_return(nil)
            expect{ Osm::Email::DeliveryReport::Email.fetch_from_osm(api: $api, section: 1, email: 2) }.to raise_error Osm::Error, 'Unexpected format for response - got a NilClass'
          end

          it "Got an error from OSM" do
            expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').and_return({'success'=>false, 'error'=>'Error message'})
            expect{ Osm::Email::DeliveryReport::Email.fetch_from_osm(api: $api, section: 1, email: 2) }.to raise_error Osm::Error, 'Error message'
          end

        end

        it "Error getting body" do
          expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmail&section_id=1&email_id=2&email=&member_id=').and_return({'data'=>{'to'=>'1 Recipient', 'from'=>'"From" <from@example.com>', 'subject'=>'Subject of email', 'sent'=>'16/04/2016 13:45'}, 'status'=>true, 'error'=>nil, 'meta'=>[]})
          expect($api).to receive(:post_query).with('ext/settings/emails/?action=getSentEmailContent&section_id=1&email_id=2&email=&member_id=').once{ raise Osm::Forbidden, 'Email not found' }
          expect{ Osm::Email::DeliveryReport::Email.fetch_from_osm(api: $api, section: 1, email: 2) }.to raise_error Osm::Error, 'Email not found'
        end

      end # describe Email -> DeliveryReport -> Email : fetch email from osm

    end # describe Email -> DeliveryReport -> Email

  end # describe Email -> DeliveryReport

end
