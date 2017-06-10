describe Osm do

  describe 'Make a DateTime' do
    it 'is given a date and a time' do
      expect(Osm.make_datetime(date: '2001-02-03', time: '04:05:06')).to eq(DateTime.new(2001, 02, 03, 04, 05, 06))
    end

    it 'is given just a date' do
      expect(Osm.make_datetime(date: '2001-02-03')).to eq(DateTime.new(2001, 02, 03, 00, 00, 00))
      expect(Osm.make_datetime(date: '2001-02-03', time: '')).to eq(DateTime.new(2001, 02, 03, 00, 00, 00))
    end

    it 'is given just a time' do
      expect(Osm.make_datetime(time: '01:02:03')).to be_nil
      expect(Osm.make_datetime(time: '01:02:03', date: '')).to be_nil
    end

    it 'is given neither' do
      expect(Osm.make_datetime()).to be_nil
      expect(Osm.make_datetime(date: '', time: '')).to be_nil
    end

    it 'is given an invalid date' do
      expect(Osm.make_datetime(date: 'No date here1', time: '04:05:06')).to be_nil
    end

    it 'is given an invalid time' do
      expect(Osm.make_datetime(date: '2001-02-03', time: 'No time here!')).to be_nil
    end

    it 'is given just an invalid date' do
      expect(Osm.make_datetime(date: 'No date here1')).to be_nil
    end

    it 'is given just an invalid time' do
      expect(Osm.make_datetime(time: 'No time here1')).to be_nil
    end

    it 'ignores the epoch date if required' do
      allow(Osm).to receive(:epoch_date?){ true }
      expect(Osm.make_datetime(date: '1970-01-01', ignore_epoch: true)).to be_nil
    end

    it 'accepts the epoch date if required' do
      allow(Osm).to receive(:epoch_date?){ true }
      expect(Osm.make_datetime(date: '1970-01-01', ignore_epoch: false)).to eq(DateTime.new(1970, 1, 1))
    end
  end


  describe 'Parse for a datetime' do
    it 'is not given a date' do
      expect(Osm.parse_datetime(nil)).to be_nil
      expect(Osm.parse_datetime('')).to be_nil
    end

    it 'is given a valid datetime' do
      expect(Osm.parse_datetime('2001-02-03 04:05:06')).to eq(DateTime.new(2001, 2, 3, 4, 5, 6))
    end

    it 'is given an invalid datetime' do
      expect(Osm.parse_datetime('la;jsndf')).to be_nil
    end
  end


  describe 'Parse for a date' do
    it 'is not given a date' do
      expect(Osm.parse_date(nil)).to be_nil
      expect(Osm.parse_date('')).to be_nil
    end

    it 'is given a valid date string' do
      expect(Osm.parse_date('2001-02-03')).to eq(Date.new(2001, 02, 03))
    end

    it 'is given an invalid date string' do
      expect(Osm.parse_date('No date here!')).to be_nil
    end

    it 'is given a human date' do
      expect(Osm.parse_date('03/02/2001')).to eq(Date.new(2001, 02, 03))
      expect(Osm.parse_date('3/2/2001')).to eq(Date.new(2001, 02, 03))
    end

    it 'ignores the epoch date if required' do
      allow(Osm).to receive(:epoch_date?){ true }
      expect(Osm.parse_date('1970-01-01', ignore_epoch: true)).to be_nil
    end

    it 'accepts the epoch date if required' do
      allow(Osm).to receive(:epoch_date?){ true }
      expect(Osm.parse_date('1970-01-01', ignore_epoch: false)).to eq(Date.new(1970, 1, 1))
    end

  end


  describe 'Check if a date is the epoch' do
    it 'given a date' do
      expect(Osm.epoch_date?(Date.new(1970, 1, 1))).to be true
      expect(Osm.epoch_date?(Date.new(2000, 1, 1))).to be false
    end

    it 'given a datetime' do
      expect(Osm.epoch_date?(DateTime.new(1970, 1, 1, 3, 4, 5))).to be true
      expect(Osm.epoch_date?(DateTime.new(2000, 1, 1, 3, 4, 5))).to be false
    end

    it 'given a string' do
      expect(Osm.epoch_date?('1970-01-01')).to be true
      expect(Osm.epoch_date?('2000-01-01')).to be false
    end
  end


  describe 'Convert to integer or nil' do
    it 'given an integer in a string' do
      expect(Osm.to_i_or_nil('1')).to eq(1)
    end

    it 'given nil' do
      expect(Osm.to_i_or_nil(nil)).to be_nil
    end

    it 'given text in a string' do
      expect(Osm.to_i_or_nil('a')).to eq(0)
    end

    it 'given something without a to_i method' do
      expect(Osm.to_i_or_nil(:a)).to be_nil
    end
  end


  describe 'Symbolize a hash' do
    it 'not given a hash' do
      expect {
        Osm.symbolize_hash('abc')
      }.to raise_error(ArgumentError, 'You did not pass in a hash')
    end

    it 'given a hash' do
      hash_in = {
        '1' => 1,
        :a  => 'a',
        'b' => 'b'
      }
      hash_out = {
        :'1' => 1,
        :a   => 'a',
        :b   => 'b'
      }
      expect(Osm.symbolize_hash(hash_in)).to eq(hash_out)
    end
  end


  describe 'Inspect instance' do

    class TestA < Osm::Model
      attribute :id
      attribute :b
    end
    class TestB < Osm::Model
      attribute :id
      attribute :a
    end

    it 'Returns a string' do
      this_one = TestA.new(id: 1, b: '1')
      inspect = Osm.inspect_instance(this_one)
      expect(inspect).to eq('#<TestA b: "1", id: 1 >')
    end

    it 'Replaces items with their attribute' do
      this_one = TestA.new(id: 1, b: TestB.new(id: 2))
      inspect = Osm.inspect_instance(this_one, options={ replace_with: { 'b' => :id } })
      expect(inspect).to eq('#<TestA b.id: 2, id: 1 >')
    end

  end


  describe 'Make permissions Hash' do

    it 'Make the hash' do
      from_osm = {
        'badge' => 100,
        'programme' => 20,
        'events' => 10
      }
      expect(Osm.make_permissions_hash(from_osm)).to eq(        badge: [:read, :write, :administer],
        programme: [:read, :write],
        events: [:read])
    end

    it 'Includes only relevant permissions' do
      from_osm = {
        't' => true,
        'f' => false,
        'badge' => 100
      }
      expect(Osm.make_permissions_hash(from_osm).keys).to eq([:badge])
    end

  end

end
