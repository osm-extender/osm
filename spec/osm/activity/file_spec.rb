describe OSM::Activity::File do

  it 'Sorts by activity_id then name' do
    expect(OSM::Activity::File.new.send(:sort_by)).to eq(['activity_id', 'name'])
  end

end
