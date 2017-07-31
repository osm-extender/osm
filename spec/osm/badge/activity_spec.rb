describe OSM::Badge::Activity do

  it 'Has a type' do
    expect(described_class.type).to eq :activity
  end

  it 'Has a type_id' do
    expect(described_class.type_id).to eq 2
  end

  it 'Has a required subscription' do
    expect(described_class.send(:subscription_required)).to eq :silver
  end

end
