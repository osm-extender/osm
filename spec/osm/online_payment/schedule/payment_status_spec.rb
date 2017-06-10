describe Osm::OnlinePayment::Schedule::PaymentStatus do

  it 'Create' do
    payment = Osm::OnlinePayment::Schedule::Payment.new
    allow(payment).to receive('valid?'){ true }
    status = Osm::OnlinePayment::Schedule::PaymentStatus.new(
      id:             1,
      payment:        payment,
      details:        'Details',
      timestamp:      Time.new(2016, 4, 5, 6, 7),
      status:         :paid,
      updated_by:     'My.SCOUT',
      updated_by_id:  -2
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

  it 'Sorts by timestamp (desc), payment then id' do
    status1 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 6), payment: 1, id: 1)
    status2 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 5), payment: 1, id: 1)
    status3 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 5), payment: 2, id: 1)
    status4 = Osm::OnlinePayment::Schedule::PaymentStatus.new(timestamp: Time.new(2016, 1, 2, 3, 5), payment: 2, id: 2)
    statuses = [status3, status1, status4, status2]
    expect(statuses.sort).to eq([status1, status2, status3, status4])
  end

  describe 'Has status checking method for' do
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
  end # describe has status checking method for

end
