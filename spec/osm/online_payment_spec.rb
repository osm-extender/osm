# encoding: utf-8
require 'spec_helper'

describe "Online payments" do

  describe "Schedule" do

    it "Create" do
      schedule = Osm::OnlinePayment::Schedule.new(
        id:             1,
        section_id:     2,
        account_id:     3,
        name:           'A payment schedule',
        description:    'What this payment schedule is used for',
        archived:       true,
        gift_aid:       true,
        require_all:    true,
        pay_now:        14,
        annual_limit:   '100',
        payments:       [],
      )
      schedule.id.should == 1
      schedule.section_id.should == 2
      schedule.account_id.should == 3
      schedule.name.should == 'A payment schedule'
      schedule.description.should == 'What this payment schedule is used for'
      schedule.archived.should == true
      schedule.gift_aid.should == true
      schedule.require_all.should == true
      schedule.pay_now.should == 14
      schedule.annual_limit.should == '100'
      schedule.payments.should == []
      schedule.valid?.should == true
    end

    it "Provides current payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new(payments: [payment1, payment2])
      schedule.current_payments.should == [payment1]
    end

    it "Checks for current payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new()

      schedule.payments = [payment1]
      schedule.current_payments?.should == true

      schedule.payments = [payment2]
      schedule.current_payments?.should == false
    end

    it "Provides archived payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new(payments: [payment1, payment2])
      schedule.archived_payments.should == [payment2]
    end

    it "Checks for archived payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new()

      schedule.payments = [payment2]
      schedule.archived_payments?.should == true

      schedule.payments = [payment1]
      schedule.archived_payments?.should == false
    end

    it "Sorts by section_id, name then id" do
      schedule1 = Osm::OnlinePayment::Schedule.new(section_id: 1, name: 'A', id: 1)
      schedule2 = Osm::OnlinePayment::Schedule.new(section_id: 2, name: 'A', id: 1)
      schedule3 = Osm::OnlinePayment::Schedule.new(section_id: 2, name: 'B', id: 1)
      schedule4 = Osm::OnlinePayment::Schedule.new(section_id: 2, name: 'B', id: 2)
      schedules = [schedule3, schedule2, schedule4, schedule1]
      schedules.sort.should == [schedule1, schedule2, schedule3, schedule4]
    end

    it "Converts to a string" do
      schedule = Osm::OnlinePayment::Schedule.new(id: 1, name: 'Name')
      schedule.to_s.should == '1 -> Name'
    end


    describe "Uses OSM's API" do

      it "Gets summary list" do
        @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=getSchemes&sectionid=1'){ {'items'=>[{"schemeid"=>"539","name"=>"Events"}]} }
        result = Osm::OnlinePayment::Schedule.get_list_for_section(@api, 1)
        result.should == [{id: 539, name: 'Events'}]
      end

      it "Gets an individual schedule" do
        data = {"schemeid"=>"2","sectionid"=>"1","accountid"=>"3","name"=>"Schedule name","preauth_amount"=>"12.34","description"=>"Schedule description","giftaid"=>"1","defaulton"=>"1","paynow"=>"-1","archived"=>"1","payments"=>[{"paymentid"=>"4","schemeid"=>"2","date"=>"2013-03-21","amount"=>"1.23","name"=>"Payment name","archived"=>"1"}]}
        @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=getPaymentSchedule&sectionid=1&schemeid=2&allpayments=true'){ data }
        schedule = Osm::OnlinePayment::Schedule.get(@api, 1, 2)
        schedule.id.should == 2
        schedule.section_id.should == 1
        schedule.account_id.should == 3
        schedule.name.should == 'Schedule name'
        schedule.description.should == 'Schedule description'
        schedule.archived.should == true
        schedule.gift_aid.should == true
        schedule.require_all.should == true
        schedule.pay_now.should == -1
        schedule.annual_limit.should == '12.34'
        schedule.payments.count.should == 1
        schedule.valid?.should == true
        payment = schedule.payments[0]
        payment.id.should == 4
        payment.amount.should == '1.23'
        payment.name.should == 'Payment name'
        payment.archived.should == true
        payment.due_date.should == Date.new(2013, 3, 21)
        payment.schedule.should == schedule
        payment.valid?.should == true
      end

      it "Gets all schedules for a section" do
        Osm::OnlinePayment::Schedule.should_receive(:get_list_for_section).with(@api, 5, {}){ [{id: 6, name: 'A'}, {id: 7, name: 'B'}] }
        Osm::OnlinePayment::Schedule.should_receive(:get).with(@api, 5, 6, {}){ 'A' }
        Osm::OnlinePayment::Schedule.should_receive(:get).with(@api, 5, 7, {}){ 'B' }
        Osm::OnlinePayment::Schedule.get_for_section(@api, 5).should == ['A', 'B']
      end

      describe "Gets member's payments" do

        before :each do
          @payment = Osm::OnlinePayment::Schedule::Payment.new(id: 4)
          @schedule = Osm::OnlinePayment::Schedule.new(
            id:         1,
            section_id: 2,
            payments:   [@payment]
          )
          body = {'items'=>[ {
            'directdebit'=>'Active', 'firstname'=>'John', 'lastname'=>'Snow', 'patrolid'=>'5', 'scoutid'=>'6',
            'startdate'=>'2015-02-03',
            '4'=>'{"status":[{"statusid":"7","scoutid":"6","schemeid":"1","paymentid":"8","statustimestamp":"03/02/2016 20:51","status":"Paid manually","details":"","editable":"1","latest":"1","who":"0","firstname":"System"}]}',
          } ]}
          @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=getPaymentStatus&sectionid=2&schemeid=1&termid=3').once{ body }
        end

        it 'For a "collect all" schedule' do
          @schedule.require_all = true
          p4m = @schedule.get_payments_for_members(@api, 3)
          p4m.is_a?(Array).should == true
          p4m.size.should == 1
          p4m = p4m[0]
          p4m.member_id.should == 6
          p4m.first_name.should == 'John'
          p4m.last_name.should == 'Snow'
          p4m.start_date.should == Date.new(2015, 2, 3)
          p4m.direct_debit.should == :active
          p4m.payments.size.should == 1
          payment = p4m.payments[4][0]
          payment.id.should == 7
          payment.payment.should == @payment
          payment.timestamp.should == Time.new(2016, 2, 3, 20, 51)
          payment.status.should == :paid_manually
          payment.details.should == ''
          payment.updated_by.should == 'System'
          payment.updated_by_id.should == 0
          payment.valid?.should == true
          p4m.valid?.should == true
        end

        it 'For a "not collect all" schedule' do
          @schedule.require_all = false
          p4m = @schedule.get_payments_for_members(@api, 3)[0]
          p4m.start_date.should == nil    # Only difference to a "collect all" type
          p4m.valid?.should == true
        end

        it "When it needs to fetch a term" do
          section = Osm::Section.new(id: 2)
          Osm::Term.stub(:get_current_term_for_section).and_return(Osm::Term.new(id: 3))
          Osm::Section.stub(:get).and_return(section)
          p4m = @schedule.get_payments_for_members(@api)[0]
          p4m.member_id.should == 6
          p4m.valid?.should == true
        end

      end # describe Schedule : Uses OSM's API : Get member's payments

    end # describe Schedule : Uses OSM's API


    describe "Payment" do

      it "Create" do
        schedule = Osm::OnlinePayment::Schedule.new()
        schedule.stub('valid?'){ true }
        payment = Osm::OnlinePayment::Schedule::Payment.new(
          id:       1,
          amount:   '12.34',
          name:     'A payment',
          archived: true,
          due_date: Date.new(2016, 5, 1),
          schedule: schedule,
        )
        payment.id.should == 1
        payment.amount.should == '12.34'
        payment.name.should == 'A payment'
        payment.archived.should == true
        payment.due_date.should == Date.new(2016, 5, 1)
        payment.schedule.should == schedule
        payment.valid?.should == true
      end

      it "Checks if a payment is past due" do
        payment = Osm::OnlinePayment::Schedule::Payment.new(due_date: Date.new(2016, 5, 2))
        payment.past_due?(Date.new(2016, 5, 1)).should == false
        payment.past_due?(Date.new(2016, 5, 2)).should == false
        payment.past_due?(Date.new(2016, 5, 3)).should == true
      end

    end # describe Schedule -> Payment


    describe "PaymentsForMember" do

      it "Create" do
        schedule = Osm::OnlinePayment::Schedule.new
        p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(
          first_name:     'John',
          last_name:      'Smith',
          member_id:      1,
          direct_debit:   :active,
          start_date:     Date.new(2016, 6, 7),
          payments:       {},
          schedule:       schedule,
        )
        p4m.first_name.should == 'John'
        p4m.last_name.should == 'Smith'
        p4m.member_id.should == 1
        p4m.direct_debit.should == :active
        p4m.start_date.should == Date.new(2016, 6, 7)
        p4m.payments.should == {}
        p4m.schedule.should == schedule
        p4m.valid?.should == true
      end

      it "Gets most recent status for a payment" do
        payments = {
          1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 1, timestamp: Time.new(2016, 1, 2, 3, 4))],
          2 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 2, timestamp: Time.new(2016, 1, 2, 3, 4))],
          3 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 3, timestamp: Time.new(2016, 1, 2, 3, 4)), Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 4, timestamp: Time.new(2016, 1, 2, 3, 5))],
        }
        p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(payments: payments)

        p4m.latest_status_for(1).id.should == 1
        p4m.latest_status_for(Osm::OnlinePayment::Schedule::Payment.new(id: 2)).id.should == 2
        p4m.latest_status_for(3).id.should == 4
      end

      it "Works out if a payment is paid" do
        payments = {
          1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :required)],
          2 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :not_required)],
          3 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :initiated)],
          4 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :paid)],
          5 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :received)],
          6 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :paid_manually)],
        }
        p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(payments: payments)

        p4m.paid?(1).should == false
        p4m.paid?(2).should == false
        p4m.paid?(3).should == true
        p4m.paid?(4).should == true
        p4m.paid?(5).should == true
        p4m.paid?(6).should == true
        p4m.paid?(7).should == nil
      end

      it "Works out if a payment is unpaid" do
        payments = {
          1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :required)],
          2 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :not_required)],
          3 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :initiated)],
          4 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :paid)],
          5 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :received)],
          6 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :paid_manually)],
        }
        p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(payments: payments)

        p4m.unpaid?(1).should == true
        p4m.unpaid?(2).should == false
        p4m.unpaid?(3).should == false
        p4m.unpaid?(4).should == false
        p4m.unpaid?(5).should == false
        p4m.unpaid?(6).should == false
        p4m.unpaid?(7).should == nil
      end

      it "Tells if the user has an active direct debit" do
        p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(direct_debit: :active)
        p4m.active_direct_debit?.should == true

        p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(direct_debit: :inactive)
        p4m.active_direct_debit?.should == false
      end

      describe "Works out if a payment is over due" do

        before :each do
          @payment = Osm::OnlinePayment::Schedule::Payment.new(id: 1, due_date: Date.new(2016, 1, 2))
          paid_payments = { 1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :paid, payment: @payment)] }
          @paid = Osm::OnlinePayment::Schedule::PaymentsForMember.new(payments: paid_payments)
          unpaid_payments = { 1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :required, payment: @payment)] }
          @unpaid = Osm::OnlinePayment::Schedule::PaymentsForMember.new(payments: unpaid_payments)
        end

        it "Due date in over" do
          date = Date.new(2016, 1, 3)
          @paid.over_due?(@payment, date).should == false
          @unpaid.over_due?(@payment, date).should == true
        end

        it "Due date in present" do
          # Due today means that it is not over being due
          date = Date.new(2016, 1, 2)
          @paid.over_due?(@payment, date).should == false
          @unpaid.over_due?(@payment, date).should == false
        end

        it "Due date in future" do
          date = Date.new(2016, 1, 1)
          @paid.over_due?(@payment, date).should == false
          @unpaid.over_due?(@payment, date).should == false
        end

      end # describe Schedule -> PaymentsForMember : is payment past due?

      describe "Update a payment in OSM" do

        before :each do
          @schedule = Osm::OnlinePayment::Schedule.new(id: 10, section_id: 4, gift_aid: true)
          @payment = Osm::OnlinePayment::Schedule::Payment.new(id: 1, schedule: @schedule)
          @schedule.payments = [@payment]
          @status = Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 2, payment: @payment)
          @p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(member_id: 3, payments: {1=>[@status]}, schedule: @schedule)
        end

        describe "Using update_payment_status method" do
          it "Success" do
            @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>false,'value'=>'Payment not required'})
              .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled', '1'=>'{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Payment not required","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}'} }
            @p4m.update_payment_status(@api, @payment, :not_required).should == true
          end

          describe "Failure" do
            it "No history for payment" do
              @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>true,'value'=>'Paid manually'})
                .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled', '1'=>'{"status":[]}'} }
              @p4m.update_payment_status(@api, @payment, :paid_manually, true).should == false
            end

            it "No payment data" do
              @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>true,'value'=>'Paid manually'})
                .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled'} }
              @p4m.update_payment_status(@api, @payment, :paid_manually, true).should == false
            end

            it "Latest status is not what we set" do
              @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>true,'value'=>'Paid manually'})
                .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled', '1'=>'{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Payment not required","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}'} }
              @p4m.update_payment_status(@api, @payment, :paid_manually, true).should == false
            end
          end

          it "Fails if payment is not in the schedule" do
            expect{ @p4m.update_payment_status(@api, 2, :paid_manually) }.to raise_error ArgumentError, '2 is not a valid payment for the schedule.'
          end

          it "Fails if given a bad status" do
            expect{ @p4m.update_payment_status(@api, 1, :invalid) }.to raise_error ArgumentError, 'status must be either :required, :not_required or :paid_manually. You passed in :invalid'
          end

          describe "Ignores gift aid parameter if appropriate" do # pass in true and check if calls out with false
            it "Schedule is a gift aid one" do
              @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>true,'value'=>'Paid manually'})
                .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled', '1'=>'{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Paid manually","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}'} }
              @p4m.update_payment_status(@api, @payment, :paid_manually, true).should == true
            end

            it "Schedule is NOT a gift aid one" do
              @schedule.gift_aid = false
              @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>false,'value'=>'Paid manually'})
                .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled', '1'=>'{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Paid manually","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}'} }
              @p4m.update_payment_status(@api, @payment, :paid_manually, true).should == true
            end
          end

        end # Using update_payment_status method

        describe "Using" do
          it "mark_payment_required" do
            @p4m.should_receive(:update_payment_status).with(@api, @payment, :required).once{ true }
            @p4m.mark_payment_required(@api, @payment).should == true
          end

          it "mark_payment_not_required" do
            @p4m.should_receive(:update_payment_status).with(@api, @payment, :not_required).once{ true }
            @p4m.mark_payment_not_required(@api, @payment).should == true
          end

          describe "mark_payment_paid_manually" do
            it "Updating gift aid" do
              @p4m.should_receive(:update_payment_status).with(@api, @payment, :paid_manually, true).once{ true }
              @p4m.mark_payment_paid_manually(@api, @payment, true).should == true
            end

            it "Not updating gift aid" do
              @p4m.should_receive(:update_payment_status).with(@api, @payment, :paid_manually, false).once{ true }
              @p4m.mark_payment_paid_manually(@api, @payment, false).should == true
            end
          end

        end

      end # describe Schedule -> PaymentsForMember : Update a payment in OSM

    end # describe Schedule -> PaymentsForMember


    describe "Payment status" do

      it "Create" do
        payment = Osm::OnlinePayment::Schedule::Payment.new
        payment.stub('valid?'){ true }
        status = Osm::OnlinePayment::Schedule::PaymentStatus.new(
          id:             1,
          payment:        payment,
          details:        'Details',
          timestamp:      Time.new(2016, 4, 5, 6, 7),
          status:         :paid,
          updated_by:     'My.SCOUT',
          updated_by_id:  -2,
        )
        status.id.should == 1
        status.payment.should == payment
        status.details.should == 'Details'
        status.timestamp.should == Time.new(2016, 4, 5, 6, 7)
        status.status.should == :paid
        status.updated_by.should == 'My.SCOUT'
        status.updated_by_id.should == -2
        status.valid?.should == true
      end

      it "Sorts by timestamp (desc), payment then id" do
        status1 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 6), payment: 1, id: 1)
        status2 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 5), payment: 1, id: 1)
        status3 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 5), payment: 2, id: 1)
        status4 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 5), payment: 2, id: 2)
        statuses = [status3, status1, status4, status2]
        statuses.sort.should == [status1, status2, status3, status4]
      end

      describe "Has status checking method for" do
        before :each do
          @payments = []
          Osm::OnlinePayment::Schedule::PaymentStatus::VALID_STATUSES.each do |status|
            payment = Osm::OnlinePayment::Schedule::PaymentStatus.new(status: status)
            @payments.push payment
            instance_variable_set("@#{status}_payment", payment)
          end
        end

        Osm::OnlinePayment::Schedule::PaymentStatus::VALID_STATUSES.each do |status|
          it status.to_s do
            payment = instance_variable_get("@#{status}_payment")
            payment.send("#{status}?").should == true
            (Osm::OnlinePayment::Schedule::PaymentStatus::VALID_STATUSES - [status]).each do |i|
              payment.send("#{i}?").should == false
            end
          end
        end
      end

    end # describe Schedule -> PaymentStatus


  end # describe Schedule

end
