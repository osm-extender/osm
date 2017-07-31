describe OSM::Badge::Challenge do

  it 'Has a type' do
    expect(described_class.type).to eq :challenge
  end

  it 'Has a type_id' do
    expect(described_class.type_id).to eq 1
  end

  it 'Has a required subscription' do
    expect(described_class.send(:subscription_required)).to eq :bronze
  end

end
