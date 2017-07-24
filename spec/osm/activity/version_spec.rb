describe OSM::Activity::Version do

  it 'Sorts by activity_id then version' do
    expect(OSM::Activity::Version.new.send(:sort_by)).to eq(['activity_id', 'version'])
  end

end
