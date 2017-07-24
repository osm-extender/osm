describe OSM::GiftAid::Donation do

  it 'Create' do
    d = OSM::GiftAid::Donation.new(
      donation_date: Date.new(2000, 1, 2)
    )

    expect(d.donation_date).to eq(Date.new(2000, 1, 2))
    expect(d.valid?).to eq(true)
  end

  it 'Sorts by date' do
    d1 = OSM::GiftAid::Donation.new(donation_date: Date.new(2000, 1, 2))
    d2 = OSM::GiftAid::Donation.new(donation_date: Date.new(2001, 1, 2))

    data = [d2, d1]
    expect(data.sort).to eq([d1, d2])
  end

end
