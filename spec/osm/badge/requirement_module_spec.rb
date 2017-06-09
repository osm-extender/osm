describe Osm::Badge::RequirementModule do

  it "Create" do
    b = Osm::Badge.new
    m = Osm::Badge::RequirementModule.new(
      badge: b,
      id: 567,
      letter: 'a',
      min_required: 1,
      custom_columns: 2,
      completed_into_column: 3,
      numeric_into_column: 4,
      add_column_id_to_numeric: 5,
    )

    expect(m.badge).to eq(b)
    expect(m.id).to eq(567)
    expect(m.letter).to eq('a')
    expect(m.min_required).to eq(1)
    expect(m.custom_columns).to eq(2)
    expect(m.completed_into_column).to eq(3)
    expect(m.numeric_into_column).to eq(4)
    expect(m.add_column_id_to_numeric).to eq(5)
    expect(m.valid?).to eq(true)
  end

  it "Compare by badge then letter then id" do
    b1 = Osm::Badge::RequirementModule.new(badge: Osm::Badge.new(name: 'A'), letter: 'a', id: 1)
    b2 = Osm::Badge::RequirementModule.new(badge: Osm::Badge.new(name: 'B'), letter: 'a', id: 1)
    b3 = Osm::Badge::RequirementModule.new(badge: Osm::Badge.new(name: 'B'), letter: 'b', id: 1)
    b4 = Osm::Badge::RequirementModule.new(badge: Osm::Badge.new(name: 'B'), letter: 'b', id: 2)
    badges = [b3, b4, b1, b2]
    expect(badges.sort).to eq([b1, b2, b3, b4])
  end

end
