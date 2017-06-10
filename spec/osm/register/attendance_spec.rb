describe Osm::Register::Attendance do

  it 'Create' do
    rd = Osm::Register::Attendance.new(
      member_id: '1',
      first_name: 'A',
      last_name: 'B',
      section_id: '2',
      grouping_id: '3',
      total: 4,
      attendance: {
        Date.new(2012, 1, 10) => :yes,
        Date.new(2012, 1, 24) => :unadvised_absent
      }
    )

    expect(rd.member_id).to eq(1)
    expect(rd.section_id).to eq(2)
    expect(rd.grouping_id).to eq(3)
    expect(rd.first_name).to eq('A')
    expect(rd.last_name).to eq('B')
    expect(rd.total).to eq(4)
    expect(rd.attendance).to eq(      Date.new(2012, 01, 10) => :yes,
      Date.new(2012, 01, 24) => :unadvised_absent)
    expect(rd.valid?).to eq(true)
  end

  it 'Sorts by section_id, grouping_id, last_name then first_name' do
    d1 = Osm::Register::Attendance.new(section_id: 1, grouping_id: 1, last_name: 'a', first_name: 'a')
    d2 = Osm::Register::Attendance.new(section_id: 2, grouping_id: 1, last_name: 'a', first_name: 'a')
    d3 = Osm::Register::Attendance.new(section_id: 2, grouping_id: 2, last_name: 'a', first_name: 'a')
    d4 = Osm::Register::Attendance.new(section_id: 2, grouping_id: 2, last_name: 'b', first_name: 'a')
    d5 = Osm::Register::Attendance.new(section_id: 2, grouping_id: 2, last_name: 'b', first_name: 'b')

    data = [d4, d3, d5, d2, d1]
    expect(data.sort).to eq([d1, d2, d3, d4, d5])
  end

  it 'Reports if a member was present on a date' do
    date = Date.new(2000, 1, 1)
    expect(Osm::Register::Attendance.new(attendance: { date => :yes }).present_on?(date)).to eq(true)
    expect(Osm::Register::Attendance.new(attendance: { date => :known_absent }).present_on?(date)).to eq(false)
    expect(Osm::Register::Attendance.new(attendance: { date => :unknown_absent }).present_on?(date)).to eq(false)
  end

  it 'Reports if a member was absent on a date' do
    date = Date.new(2000, 1, 1)
    expect(Osm::Register::Attendance.new(attendance: { date => :yes }).absent_on?(date)).to eq(false)
    expect(Osm::Register::Attendance.new(attendance: { date => :known_absent }).absent_on?(date)).to eq(true)
    expect(Osm::Register::Attendance.new(attendance: { date => :unknown_absent }).absent_on?(date)).to eq(true)
  end

end
