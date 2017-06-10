describe Osm::Event::BadgeLink do

  it 'Create' do
    bl = Osm::Event::BadgeLink.new(
      badge_type: :activity,
      badge_section: :cubs,
      requirement_label: 'A: Poster',
      data: 'abc',
      badge_name: 'Artist',
      badge_id: 1,
      badge_version: 0,
      requirement_id: 2,
    )

    expect(bl.badge_type).to eq(:activity)
    expect(bl.badge_section).to eq(:cubs)
    expect(bl.badge_name).to eq('Artist')
    expect(bl.badge_id).to eq(1)
    expect(bl.badge_version).to eq(0)
    expect(bl.requirement_id).to eq(2)
    expect(bl.requirement_label).to eq('A: Poster')
    expect(bl.data).to eq('abc')
    expect(bl.valid?).to eq(true)
  end


  describe 'Using to OSM API' do
  end # describe using to OSM API

end
