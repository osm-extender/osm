describe Osm::Activity::Version do

  it 'Sorts by activity_id then version' do
    expect(Osm::Activity::Version.new.send(:sort_by)).to eq(['activity_id', 'version'])
  end

end
