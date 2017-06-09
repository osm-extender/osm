describe Osm::Member::Contact do

  it "Provides full name" do
    expect(Osm::Member::Contact.new(first_name: 'First').name).to eq('First')
    expect(Osm::Member::Contact.new(last_name: 'Last').name).to eq('Last')
    expect(Osm::Member::Contact.new(first_name: 'First', last_name: 'Last').name).to eq('First Last')
    expect(Osm::Member::Contact.new(first_name: 'First', last_name: 'Last').name('*')).to eq('First*Last')
  end

end
