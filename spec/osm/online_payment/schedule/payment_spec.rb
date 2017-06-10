describe Osm::OnlinePayment::Schedule::Payment do

  it 'Create' do
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

  it 'Checks if a payment is past due' do
    payment = Osm::OnlinePayment::Schedule::Payment.new(due_date: Date.new(2016, 5, 2))
    expect(payment.past_due?(Date.new(2016, 5, 1))).to eq(false)
    expect(payment.past_due?(Date.new(2016, 5, 2))).to eq(false)
    expect(payment.past_due?(Date.new(2016, 5, 3))).to eq(true)
  end

end
