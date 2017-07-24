describe OSM::Register::Field do

  it 'Create' do
    field = OSM::Register::Field.new(
      name: 'Human name',
      id: 'machine_name',
      tooltip: 'Tooltip'
    )

    expect(field.id).to eq('machine_name')
    expect(field.name).to eq('Human name')
    expect(field.tooltip).to eq('Tooltip')
    expect(field.valid?).to eq(true)
  end

  it 'Sorts by id' do
    a1 = OSM::Register::Field.new(id: 'a')
    a2 = OSM::Register::Field.new(id: 'a')

    data = [a2, a1]
    expect(data.sort).to eq([a1, a2])
  end

end
