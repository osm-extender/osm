describe Osm::Badge::Requirement do

  it 'Create' do
    m = Osm::Badge::RequirementModule.new
    requirement = Osm::Badge::Requirement.new(
      name: 'name',
      description: 'description',
      mod: m,
      id: 1,
      editable: true,
      badge: Osm::Badge.new(identifier: 'key')
    )

    expect(requirement.name).to eq('name')
    expect(requirement.description).to eq('description')
    expect(requirement.mod).to eq(m)
    expect(requirement.id).to eq(1)
    expect(requirement.editable).to eq(true)
    expect(requirement.badge.identifier).to eq('key')
    expect(requirement.valid?).to eq(true)
  end

  it 'Compare by badge then id' do
    b1 = Osm::Badge::Requirement.new(badge: Osm::Badge.new(name: 'A'), id: 1)
    b2 = Osm::Badge::Requirement.new(badge: Osm::Badge.new(name: 'B'), id: 1)
    b3 = Osm::Badge::Requirement.new(badge: Osm::Badge.new(name: 'B'), id: 2)
    badges = [b3, b1, b2]
    expect(badges.sort).to eq([b1, b2, b3])
  end

end
