describe Osm::Meeting::Activity do

    it 'Create' do
      ea = Osm::Meeting::Activity.new(
        activity_id: 2,
        title: 'Activity Name',
        notes: 'Notes',
      )

      expect(ea.activity_id).to eq(2)
      expect(ea.title).to eq('Activity Name')
      expect(ea.notes).to eq('Notes')
      expect(ea.valid?).to eq(true)
    end

    it 'Sorts by title then activity_id' do
      a1 = Osm::Meeting::Activity.new(title: 'a', activity_id: 1)
      a2 = Osm::Meeting::Activity.new(title: 'b', activity_id: 1)
      a3 = Osm::Meeting::Activity.new(title: 'b', activity_id: 2)

      data = [a2, a3, a1]
      expect(data.sort).to eq([a1, a2, a3])
    end

end
