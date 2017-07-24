describe OSM::Member::Contact do

  it 'Provides full name' do
    expect(OSM::Member::Contact.new(first_name: 'First').name).to eq('First')
    expect(OSM::Member::Contact.new(last_name: 'Last').name).to eq('Last')
    expect(OSM::Member::Contact.new(first_name: 'First', last_name: 'Last').name).to eq('First Last')
    expect(OSM::Member::Contact.new(first_name: 'First', last_name: 'Last').name('*')).to eq('First*Last')
  end

end
