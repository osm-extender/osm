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
      expect(schedule.id).to eq(1)
      expect(schedule.section_id).to eq(2)
      expect(schedule.account_id).to eq(3)
      expect(schedule.name).to eq('A payment schedule')
      expect(schedule.description).to eq('What this payment schedule is used for')
      expect(schedule.archived).to eq(true)
      expect(schedule.gift_aid).to eq(true)
      expect(schedule.require_all).to eq(true)
      expect(schedule.pay_now).to eq(14)
      expect(schedule.annual_limit).to eq('100')
      expect(schedule.payments).to eq([])
      expect(schedule.valid?).to eq(true)
    end

    it "Provides current payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new(payments: [payment1, payment2])
      expect(schedule.current_payments).to eq([payment1])
    end

    it "Checks for current payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new()

      schedule.payments = [payment1]
      expect(schedule.current_payments?).to eq(true)

      schedule.payments = [payment2]
      expect(schedule.current_payments?).to eq(false)
    end

    it "Provides archived payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new(payments: [payment1, payment2])
      expect(schedule.archived_payments).to eq([payment2])
    end

    it "Checks for archived payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new()

      schedule.payments = [payment2]
      expect(schedule.archived_payments?).to eq(true)

      schedule.payments = [payment1]
      expect(schedule.archived_payments?).to eq(false)
    end

    it "Sorts by section_id, name then id" do
      schedule1 = Osm::OnlinePayment::Schedule.new(section_id: 1, name: 'A', id: 1)
      schedule2 = Osm::OnlinePayment::Schedule.new(section_id: 2, name: 'A', id: 1)
      schedule3 = Osm::OnlinePayment::Schedule.new(section_id: 2, name: 'B', id: 1)
      schedule4 = Osm::OnlinePayment::Schedule.new(section_id: 2, name: 'B', id: 2)
      schedules = [schedule3, schedule2, schedule4, schedule1]
      expect(schedules.sort).to eq([schedule1, schedule2, schedule3, schedule4])
    end

    it "Converts to a string" do
      schedule = Osm::OnlinePayment::Schedule.new(id: 1, name: 'Name')
      expect(schedule.to_s).to eq('1 -> Name')
    end


    describe "Uses OSM's API" do

      it "Gets summary list" do
        expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=getSchemes&sectionid=1'){ {'items'=>[{"schemeid"=>"539","name"=>"Events"}]} }
        result = Osm::OnlinePayment::Schedule.get_list_for_section(api: $api, section: 1)
        expect(result).to eq([{id: 539, name: 'Events'}])
      end

      it "Gets an individual schedule" do
        data = {"schemeid"=>"2","sectionid"=>"1","accountid"=>"3","name"=>"Schedule name","preauth_amount"=>"12.34","description"=>"Schedule description","giftaid"=>"1","defaulton"=>"1","paynow"=>"-1","archived"=>"1","payments"=>[{"paymentid"=>"4","schemeid"=>"2","date"=>"2013-03-21","amount"=>"1.23","name"=>"Payment name","archived"=>"1"}]}
        expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=getPaymentSchedule&sectionid=1&schemeid=2&allpayments=true'){ data }
        schedule = Osm::OnlinePayment::Schedule.get(api: $api, section: 1, schedule: 2)
        expect(schedule.id).to eq(2)
        expect(schedule.section_id).to eq(1)
        expect(schedule.account_id).to eq(3)
        expect(schedule.name).to eq('Schedule name')
        expect(schedule.description).to eq('Schedule description')
        expect(schedule.archived).to eq(true)
        expect(schedule.gift_aid).to eq(true)
        expect(schedule.require_all).to eq(true)
        expect(schedule.pay_now).to eq(-1)
        expect(schedule.annual_limit).to eq('12.34')
        expect(schedule.payments.count).to eq(1)
        expect(schedule.valid?).to eq(true)
        payment = schedule.payments[0]
        expect(payment.id).to eq(4)
        expect(payment.amount).to eq('1.23')
        expect(payment.name).to eq('Payment name')
        expect(payment.archived).to eq(true)
        expect(payment.due_date).to eq(Date.new(2013, 3, 21))
        expect(payment.schedule).to eq(schedule)
        expect(payment.valid?).to eq(true)
      end

      it "Gets all schedules for a section" do
        expect(Osm::OnlinePayment::Schedule).to receive(:get_list_for_section).with(api: $api, section: 5, no_read_cache: false){ [{id: 6, name: 'A'}, {id: 7, name: 'B'}] }
        expect(Osm::OnlinePayment::Schedule).to receive(:get).with(api: $api, section: 5, schedule: 6, no_read_cache: false){ 'A' }
        expect(Osm::OnlinePayment::Schedule).to receive(:get).with(api: $api, section: 5, schedule: 7, no_read_cache: false){ 'B' }
        expect(Osm::OnlinePayment::Schedule.get_for_section(api: $api, section: 5)).to eq(['A', 'B'])
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
          expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=getPaymentStatus&sectionid=2&schemeid=1&termid=3').once{ body }
        end

        it 'For a "collect all" schedule' do
          @schedule.require_all = true
          p4m = @schedule.get_payments_for_members(api: $api, term: 3)
          expect(p4m.is_a?(Array)).to eq(true)
          expect(p4m.size).to eq(1)
          p4m = p4m[0]
          expect(p4m.member_id).to eq(6)
          expect(p4m.first_name).to eq('John')
          expect(p4m.last_name).to eq('Snow')
          expect(p4m.start_date).to eq(Date.new(2015, 2, 3))
          expect(p4m.direct_debit).to eq(:active)
          expect(p4m.payments.size).to eq(1)
          payment = p4m.payments[4][0]
          expect(payment.id).to eq(7)
          expect(payment.payment).to eq(@payment)
          expect(payment.timestamp).to eq(Time.new(2016, 2, 3, 20, 51))
          expect(payment.status).to eq(:paid_manually)
          expect(payment.details).to eq('')
          expect(payment.updated_by).to eq('System')
          expect(payment.updated_by_id).to eq(0)
          expect(payment.valid?).to eq(true)
          expect(p4m.valid?).to eq(true)
        end

        it 'For a "not collect all" schedule' do
          @schedule.require_all = false
          p4m = @schedule.get_payments_for_members(api: $api, term: 3)[0]
          expect(p4m.start_date).to eq(nil)    # Only difference to a "collect all" type
          expect(p4m.valid?).to eq(true)
        end

        it "When it needs to fetch a term" do
          section = Osm::Section.new(id: 2)
          allow(Osm::Term).to receive(:get_current_term_for_section).and_return(Osm::Term.new(id: 3))
          allow(Osm::Section).to receive(:get).and_return(section)
          p4m = @schedule.get_payments_for_members(api: $api)[0]
          expect(p4m.member_id).to eq(6)
          expect(p4m.valid?).to eq(true)
        end

      end # describe Schedule : Uses OSM's API : Get member's payments

    end # describe Schedule : Uses OSM's API


    describe "Payment" do

      it "Create" do
        schedule = Osm::OnlinePayment::Schedule.new()
        allow(schedule).to receive('valid?'){ true }
        payment = Osm::OnlinePayment::Schedule::Payment.new(
          id:       1,
          amount:   '12.34',
          name:     'A payment',
          archived: true,
          due_date: Date.new(2016, 5, 1),
          schedule: schedule,
        )
        expect(payment.id).to eq(1)
        expect(payment.amount).to eq('12.34')
        expect(payment.name).to eq('A payment')
        expect(payment.archived).to eq(true)
        expect(payment.due_date).to eq(Date.new(2016, 5, 1))
        expect(payment.schedule).to eq(schedule)
        expect(payment.valid?).to eq(true)
      end

      it "Checks if a payment is past due" do
        payment = Osm::OnlinePayment::Schedule::Payment.new(due_date: Date.new(2016, 5, 2))
        expect(payment.past_due?(Date.new(2016, 5, 1))).to eq(false)
        expect(payment.past_due?(Date.new(2016, 5, 2))).to eq(false)
        expect(payment.past_due?(Date.new(2016, 5, 3))).to eq(true)
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
        expect(p4m.first_name).to eq('John')
        expect(p4m.last_name).to eq('Smith')
        expect(p4m.member_id).to eq(1)
        expect(p4m.direct_debit).to eq(:active)
        expect(p4m.start_date).to eq(Date.new(2016, 6, 7))
        expect(p4m.payments).to eq({})
        expect(p4m.schedule).to eq(schedule)
        expect(p4m.valid?).to eq(true)
      end

      it "Gets most recent status for a payment" do
        payments = {
          1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 1, timestamp: Time.new(2016, 1, 2, 3, 4))],
          2 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 2, timestamp: Time.new(2016, 1, 2, 3, 4))],
          3 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 3, timestamp: Time.new(2016, 1, 2, 3, 4)), Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 4, timestamp: Time.new(2016, 1, 2, 3, 5))],
        }
        p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(payments: payments)

        expect(p4m.latest_status_for(1).id).to eq(1)
        expect(p4m.latest_status_for(Osm::OnlinePayment::Schedule::Payment.new(id: 2)).id).to eq(2)
        expect(p4m.latest_status_for(3).id).to eq(4)
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

        expect(p4m.paid?(1)).to eq(false)
        expect(p4m.paid?(2)).to eq(false)
        expect(p4m.paid?(3)).to eq(true)
        expect(p4m.paid?(4)).to eq(true)
        expect(p4m.paid?(5)).to eq(true)
        expect(p4m.paid?(6)).to eq(true)
        expect(p4m.paid?(7)).to eq(nil)
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

        expect(p4m.unpaid?(1)).to eq(true)
        expect(p4m.unpaid?(2)).to eq(false)
        expect(p4m.unpaid?(3)).to eq(false)
        expect(p4m.unpaid?(4)).to eq(false)
        expect(p4m.unpaid?(5)).to eq(false)
        expect(p4m.unpaid?(6)).to eq(false)
        expect(p4m.unpaid?(7)).to eq(nil)
      end

      it "Tells if the user has an active direct debit" do
        p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(direct_debit: :active)
        expect(p4m.active_direct_debit?).to eq(true)

        p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(direct_debit: :inactive)
        expect(p4m.active_direct_debit?).to eq(false)
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
          expect(@paid.over_due?(@payment, date)).to eq(false)
          expect(@unpaid.over_due?(@payment, date)).to eq(true)
        end

        it "Due date in present" do
          # Due today means that it is not over being due
          date = Date.new(2016, 1, 2)
          expect(@paid.over_due?(@payment, date)).to eq(false)
          expect(@unpaid.over_due?(@payment, date)).to eq(false)
        end

        it "Due date in future" do
          date = Date.new(2016, 1, 1)
          expect(@paid.over_due?(@payment, date)).to eq(false)
          expect(@unpaid.over_due?(@payment, date)).to eq(false)
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
            expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>false,'value'=>'Payment not required'})
              .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled', '1'=>'{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Payment not required","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}'} }
            expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :not_required)).to eq(true)
          end

          describe "Failure" do
            it "No history for payment" do
              expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>true,'value'=>'Paid manually'})
                .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled', '1'=>'{"status":[]}'} }
              expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :paid_manually, gift_aid: true)).to eq(false)
            end

            it "No payment data" do
              expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>true,'value'=>'Paid manually'})
                .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled'} }
              expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :paid_manually, gift_aid: true)).to eq(false)
            end

            it "Latest status is not what we set" do
              expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>true,'value'=>'Paid manually'})
                .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled', '1'=>'{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Payment not required","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}'} }
              expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :paid_manually, gift_aid: true)).to eq(false)
            end
          end

          it "Fails if payment is not in the schedule" do
            expect{ @p4m.update_payment_status(api: $api, payment: 2, status: :paid_manually) }.to raise_error ArgumentError, '2 is not a valid payment for the schedule.'
          end

          it "Fails if given a bad status" do
            expect{ @p4m.update_payment_status(api: $api, payment: 1, status: :invalid) }.to raise_error ArgumentError, 'status must be either :required, :not_required or :paid_manually. You passed in :invalid'
          end

          describe "Ignores gift aid parameter if appropriate" do # pass in true and check if calls out with false
            it "Schedule is a gift aid one" do
              expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>true,'value'=>'Paid manually'})
                .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled', '1'=>'{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Paid manually","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}'} }
              expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :paid_manually, gift_aid: true)).to eq(true)
            end

            it "Schedule is NOT a gift aid one" do
              @schedule.gift_aid = false
              expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: {'sectionid'=>4,'schemeid'=>10,'scoutid'=>3,'paymentid'=>1,'giftaid'=>false,'value'=>'Paid manually'})
                .once{ {'scoutid'=>'3', 'firstname'=>'John', 'lastname'=>'Smith', 'patrolid'=>'5', 'startdate'=>'1970-01-01', 'directdebit'=>'cancelled', '1'=>'{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Paid manually","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}'} }
              expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :paid_manually, gift_aid: true)).to eq(true)
            end
          end

        end # Using update_payment_status method

        describe "Using" do
          it "mark_payment_required" do
            expect(@p4m).to receive(:update_payment_status).with(api: $api, payment: @payment, status: :required).once{ true }
            expect(@p4m.mark_payment_required(api: $api, payment: @payment)).to eq(true)
          end

          it "mark_payment_not_required" do
            expect(@p4m).to receive(:update_payment_status).with(api: $api, payment: @payment, status: :not_required).once{ true }
            expect(@p4m.mark_payment_not_required(api: $api, payment: @payment)).to eq(true)
          end

          describe "mark_payment_paid_manually" do
            it "Updating gift aid" do
              expect(@p4m).to receive(:update_payment_status).with(api: $api, payment: @payment, status: :paid_manually, gift_aid: true).once{ true }
              expect(@p4m.mark_payment_paid_manually(api: $api, payment: @payment, gift_aid: true)).to eq(true)
            end

            it "Not updating gift aid" do
              expect(@p4m).to receive(:update_payment_status).with(api: $api, payment: @payment, status: :paid_manually, gift_aid: false).once{ true }
              expect(@p4m.mark_payment_paid_manually(api: $api, payment: @payment, gift_aid: false)).to eq(true)
            end
          end

        end

      end # describe Schedule -> PaymentsForMember : Update a payment in OSM

    end # describe Schedule -> PaymentsForMember


    describe "Payment status" do

      it "Create" do
        payment = Osm::OnlinePayment::Schedule::Payment.new
        allow(payment).to receive('valid?'){ true }
        status = Osm::OnlinePayment::Schedule::PaymentStatus.new(
          id:             1,
          payment:        payment,
          details:        'Details',
          timestamp:      Time.new(2016, 4, 5, 6, 7),
          status:         :paid,
          updated_by:     'My.SCOUT',
          updated_by_id:  -2,
        )
        expect(status.id).to eq(1)
        expect(status.payment).to eq(payment)
        expect(status.details).to eq('Details')
        expect(status.timestamp).to eq(Time.new(2016, 4, 5, 6, 7))
        expect(status.status).to eq(:paid)
        expect(status.updated_by).to eq('My.SCOUT')
        expect(status.updated_by_id).to eq(-2)
        expect(status.valid?).to eq(true)
      end

      it "Sorts by timestamp (desc), payment then id" do
        status1 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 6), payment: 1, id: 1)
        status2 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 5), payment: 1, id: 1)
        status3 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 5), payment: 2, id: 1)
        status4 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 5), payment: 2, id: 2)
        statuses = [status3, status1, status4, status2]
        expect(statuses.sort).to eq([status1, status2, status3, status4])
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
            expect(payment.send("#{status}?")).to eq(true)
            (Osm::OnlinePayment::Schedule::PaymentStatus::VALID_STATUSES - [status]).each do |i|
              expect(payment.send("#{i}?")).to eq(false)
            end
          end
        end
      end

    end # describe Schedule -> PaymentStatus


  end # describe Schedule

end
