describe OSM::OnlinePayment::Schedule do


  it 'Create' do
    schedule = OSM::OnlinePayment::Schedule.new(
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
      payments:       []
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

  it 'Provides current payments' do
    payment1 = OSM::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
    payment2 = OSM::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
    schedule = OSM::OnlinePayment::Schedule.new(payments: [payment1, payment2])
    expect(schedule.current_payments).to eq([payment1])
  end

  it 'Checks for current payments' do
    payment1 = OSM::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
    payment2 = OSM::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
    schedule = OSM::OnlinePayment::Schedule.new()

    schedule.payments = [payment1]
    expect(schedule.current_payments?).to eq(true)

    schedule.payments = [payment2]
    expect(schedule.current_payments?).to eq(false)
  end

  it 'Provides archived payments' do
    payment1 = OSM::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
    payment2 = OSM::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
    schedule = OSM::OnlinePayment::Schedule.new(payments: [payment1, payment2])
    expect(schedule.archived_payments).to eq([payment2])
  end

  it 'Checks for archived payments' do
    payment1 = OSM::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
    payment2 = OSM::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
    schedule = OSM::OnlinePayment::Schedule.new()

    schedule.payments = [payment2]
    expect(schedule.archived_payments?).to eq(true)

    schedule.payments = [payment1]
    expect(schedule.archived_payments?).to eq(false)
  end

  it 'Sorts by section_id, name then id' do
    schedule1 = OSM::OnlinePayment::Schedule.new(section_id: 1, name: 'A', id: 1)
    schedule2 = OSM::OnlinePayment::Schedule.new(section_id: 2, name: 'A', id: 1)
    schedule3 = OSM::OnlinePayment::Schedule.new(section_id: 2, name: 'B', id: 1)
    schedule4 = OSM::OnlinePayment::Schedule.new(section_id: 2, name: 'B', id: 2)
    schedules = [schedule3, schedule2, schedule4, schedule1]
    expect(schedules.sort).to eq([schedule1, schedule2, schedule3, schedule4])
  end

  it 'Converts to a string' do
    schedule = OSM::OnlinePayment::Schedule.new(id: 1, name: 'Name')
    expect(schedule.to_s).to eq('1 -> Name')
  end


  describe 'Using the OSM API' do

    it 'Gets summary list' do
      expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=getSchemes&sectionid=1') { { 'items' => [{ 'schemeid' => '539', 'name' => 'Events' }] } }
      result = OSM::OnlinePayment::Schedule.get_list_for_section(api: $api, section: 1)
      expect(result).to eq([{ id: 539, name: 'Events' }])
    end

    it 'Gets an individual schedule' do
      data = { 'schemeid' => '2', 'sectionid' => '1', 'accountid' => '3', 'name' => 'Schedule name', 'preauth_amount' => '12.34', 'description' => 'Schedule description', 'giftaid' => '1', 'defaulton' => '1', 'paynow' => '-1', 'archived' => '1', 'payments' => [{ 'paymentid' => '4', 'schemeid' => '2', 'date' => '2013-03-21', 'amount' => '1.23', 'name' => 'Payment name', 'archived' => '1' }] }
      expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=getPaymentSchedule&sectionid=1&schemeid=2&allpayments=true') { data }
      schedule = OSM::OnlinePayment::Schedule.get(api: $api, section: 1, schedule: 2)
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

    it 'Gets all schedules for a section' do
      expect(OSM::OnlinePayment::Schedule).to receive(:get_list_for_section).with(api: $api, section: 5, no_read_cache: false) { [{ id: 6, name: 'A' }, { id: 7, name: 'B' }] }
      expect(OSM::OnlinePayment::Schedule).to receive(:get).with(api: $api, section: 5, schedule: 6, no_read_cache: false) { 'A' }
      expect(OSM::OnlinePayment::Schedule).to receive(:get).with(api: $api, section: 5, schedule: 7, no_read_cache: false) { 'B' }
      expect(OSM::OnlinePayment::Schedule.get_for_section(api: $api, section: 5)).to eq(['A', 'B'])
    end

    describe "Gets member's payments" do

      before :each do
        @payment = OSM::OnlinePayment::Schedule::Payment.new(id: 4)
        @schedule = OSM::OnlinePayment::Schedule.new(
          id:         1,
          section_id: 2,
          payments:   [@payment]
        )
        body = { 'items' => [ {
          'directdebit' => 'Active', 'firstname' => 'John', 'lastname' => 'Snow', 'patrolid' => '5', 'scoutid' => '6',
          'startdate' => '2015-02-03',
          '4' => '{"status":[{"statusid":"7","scoutid":"6","schemeid":"1","paymentid":"8","statustimestamp":"03/02/2016 20:51","status":"Paid manually","details":"","editable":"1","latest":"1","who":"0","firstname":"System"}]}'
        } ] }
        expect($api).to receive(:post_query).with('ext/finances/onlinepayments/?action=getPaymentStatus&sectionid=2&schemeid=1&termid=3').once { body }
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

      it 'When it needs to fetch a term' do
        section = OSM::Section.new(id: 2)
        allow(OSM::Term).to receive(:get_current_term_for_section).and_return(OSM::Term.new(id: 3))
        allow(OSM::Section).to receive(:get).and_return(section)
        p4m = @schedule.get_payments_for_members(api: $api)[0]
        expect(p4m.member_id).to eq(6)
        expect(p4m.valid?).to eq(true)
      end

    end # describe get member's payments

  end

end
