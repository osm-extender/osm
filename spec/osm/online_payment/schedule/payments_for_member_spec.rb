describe Osm::OnlinePayment::Schedule::PaymentsForMember do

  it 'Create' do
    schedule = Osm::OnlinePayment::Schedule.new
    p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(
      first_name:     'John',
      last_name:      'Smith',
      member_id:      1,
      direct_debit:   :active,
      start_date:     Date.new(2016, 6, 7),
      payments:       {},
      schedule:       schedule
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

  it 'Gets most recent status for a payment' do
    payments = {
      1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 1, timestamp: Time.new(2016, 1, 2, 3, 4))],
      2 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 2, timestamp: Time.new(2016, 1, 2, 3, 4))],
      3 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 3, timestamp: Time.new(2016, 1, 2, 3, 4)), Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 4, timestamp: Time.new(2016, 1, 2, 3, 5))]
    }
    p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(payments: payments)

    expect(p4m.latest_status_for(1).id).to eq(1)
    expect(p4m.latest_status_for(Osm::OnlinePayment::Schedule::Payment.new(id: 2)).id).to eq(2)
    expect(p4m.latest_status_for(3).id).to eq(4)
  end

  it 'Works out if a payment is paid' do
    payments = {
      1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :required)],
      2 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :not_required)],
      3 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :initiated)],
      4 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :paid)],
      5 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :received)],
      6 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :paid_manually)]
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

  it 'Works out if a payment is unpaid' do
    payments = {
      1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :required)],
      2 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :not_required)],
      3 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :initiated)],
      4 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :paid)],
      5 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :received)],
      6 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :paid_manually)]
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

  it 'Tells if the user has an active direct debit' do
    p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(direct_debit: :active)
    expect(p4m.active_direct_debit?).to eq(true)

    p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(direct_debit: :inactive)
    expect(p4m.active_direct_debit?).to eq(false)
  end

  describe 'Works out if a payment is over due' do

    before :each do
      @payment = Osm::OnlinePayment::Schedule::Payment.new(id: 1, due_date: Date.new(2016, 1, 2))
      paid_payments = { 1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :paid, payment: @payment)] }
      @paid = Osm::OnlinePayment::Schedule::PaymentsForMember.new(payments: paid_payments)
      unpaid_payments = { 1 => [Osm::OnlinePayment::Schedule::PaymentStatus.new(status: :required, payment: @payment)] }
      @unpaid = Osm::OnlinePayment::Schedule::PaymentsForMember.new(payments: unpaid_payments)
    end

    it 'Due date in over' do
      date = Date.new(2016, 1, 3)
      expect(@paid.over_due?(@payment, date)).to eq(false)
      expect(@unpaid.over_due?(@payment, date)).to eq(true)
    end

    it 'Due date in present' do
      # Due today means that it is not over being due
      date = Date.new(2016, 1, 2)
      expect(@paid.over_due?(@payment, date)).to eq(false)
      expect(@unpaid.over_due?(@payment, date)).to eq(false)
    end

    it 'Due date in future' do
      date = Date.new(2016, 1, 1)
      expect(@paid.over_due?(@payment, date)).to eq(false)
      expect(@unpaid.over_due?(@payment, date)).to eq(false)
    end

  end # describe works out if payment is overdue


  describe 'Update a payment in OSM' do

    before :each do
      @schedule = Osm::OnlinePayment::Schedule.new(id: 10, section_id: 4, gift_aid: true)
      @payment = Osm::OnlinePayment::Schedule::Payment.new(id: 1, schedule: @schedule)
      @schedule.payments = [@payment]
      @status = Osm::OnlinePayment::Schedule::PaymentStatus.new(id: 2, payment: @payment)
      @p4m = Osm::OnlinePayment::Schedule::PaymentsForMember.new(member_id: 3, payments: { 1 => [@status] }, schedule: @schedule)
    end

    describe 'Using update_payment_status method' do
      it 'Success' do
        expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: { 'sectionid' => 4, 'schemeid' => 10, 'scoutid' => 3, 'paymentid' => 1, 'giftaid' => false, 'value' => 'Payment not required' })
          .once { { 'scoutid' => '3', 'firstname' => 'John', 'lastname' => 'Smith', 'patrolid' => '5', 'startdate' => '1970-01-01', 'directdebit' => 'cancelled', '1' => '{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Payment not required","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}' } }
        expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :not_required)).to eq(true)
      end

      describe 'Failure' do
        it 'No history for payment' do
          expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: { 'sectionid' => 4, 'schemeid' => 10, 'scoutid' => 3, 'paymentid' => 1, 'giftaid' => true, 'value' => 'Paid manually' })
            .once { { 'scoutid' => '3', 'firstname' => 'John', 'lastname' => 'Smith', 'patrolid' => '5', 'startdate' => '1970-01-01', 'directdebit' => 'cancelled', '1' => '{"status":[]}' } }
          expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :paid_manually, gift_aid: true)).to eq(false)
        end

        it 'No payment data' do
          expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: { 'sectionid' => 4, 'schemeid' => 10, 'scoutid' => 3, 'paymentid' => 1, 'giftaid' => true, 'value' => 'Paid manually' })
            .once { { 'scoutid' => '3', 'firstname' => 'John', 'lastname' => 'Smith', 'patrolid' => '5', 'startdate' => '1970-01-01', 'directdebit' => 'cancelled' } }
          expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :paid_manually, gift_aid: true)).to eq(false)
        end

        it 'Latest status is not what we set' do
          expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: { 'sectionid' => 4, 'schemeid' => 10, 'scoutid' => 3, 'paymentid' => 1, 'giftaid' => true, 'value' => 'Paid manually' })
            .once { { 'scoutid' => '3', 'firstname' => 'John', 'lastname' => 'Smith', 'patrolid' => '5', 'startdate' => '1970-01-01', 'directdebit' => 'cancelled', '1' => '{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Payment not required","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}' } }
          expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :paid_manually, gift_aid: true)).to eq(false)
        end
      end

      it 'Fails if payment is not in the schedule' do
        expect { @p4m.update_payment_status(api: $api, payment: 2, status: :paid_manually) }.to raise_error ArgumentError, '2 is not a valid payment for the schedule.'
      end

      it 'Fails if given a bad status' do
        expect { @p4m.update_payment_status(api: $api, payment: 1, status: :invalid) }.to raise_error ArgumentError, 'status must be either :required, :not_required or :paid_manually. You passed in :invalid'
      end

      describe 'Ignores gift aid parameter if appropriate' do # pass in true and check if calls out with false

        it 'Schedule is a gift aid one' do
          expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: { 'sectionid' => 4, 'schemeid' => 10, 'scoutid' => 3, 'paymentid' => 1, 'giftaid' => true, 'value' => 'Paid manually' })
            .once { { 'scoutid' => '3', 'firstname' => 'John', 'lastname' => 'Smith', 'patrolid' => '5', 'startdate' => '1970-01-01', 'directdebit' => 'cancelled', '1' => '{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Paid manually","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}' } }
          expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :paid_manually, gift_aid: true)).to eq(true)
        end

        it 'Schedule is NOT a gift aid one' do
          @schedule.gift_aid = false
          expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: { 'sectionid' => 4, 'schemeid' => 10, 'scoutid' => 3, 'paymentid' => 1, 'giftaid' => false, 'value' => 'Paid manually' })
            .once { { 'scoutid' => '3', 'firstname' => 'John', 'lastname' => 'Smith', 'patrolid' => '5', 'startdate' => '1970-01-01', 'directdebit' => 'cancelled', '1' => '{"status":[{"statusid":"6","scoutid":"3","schemeid":"4","paymentid":"1","statustimestamp":"01/02/2003 04:05","status":"Paid manually","details":"","editable":"0","latest":"1","who":"0","firstname":"System generated"}]}' } }
          expect(@p4m.update_payment_status(api: $api, payment: @payment, status: :paid_manually, gift_aid: true)).to eq(true)
        end

      end # describe ignores gift aid parameter

    end # describe Using update_payment_status method

    describe 'Using' do
      it 'mark_payment_required' do
        expect(@p4m).to receive(:update_payment_status).with(api: $api, payment: @payment, status: :required).once { true }
        expect(@p4m.mark_payment_required(api: $api, payment: @payment)).to eq(true)
      end

      it 'mark_payment_not_required' do
        expect(@p4m).to receive(:update_payment_status).with(api: $api, payment: @payment, status: :not_required).once { true }
        expect(@p4m.mark_payment_not_required(api: $api, payment: @payment)).to eq(true)
      end

      describe 'mark_payment_paid_manually' do
        it 'Updating gift aid' do
          expect(@p4m).to receive(:update_payment_status).with(api: $api, payment: @payment, status: :paid_manually, gift_aid: true).once { true }
          expect(@p4m.mark_payment_paid_manually(api: $api, payment: @payment, gift_aid: true)).to eq(true)
        end

        it 'Not updating gift aid' do
          expect(@p4m).to receive(:update_payment_status).with(api: $api, payment: @payment, status: :paid_manually, gift_aid: false).once { true }
          expect(@p4m.mark_payment_paid_manually(api: $api, payment: @payment, gift_aid: false)).to eq(true)
        end
      end # describe mark_payment_paid_manually

    end # desxribe using

  end # describe Update a payment in OSM

end
