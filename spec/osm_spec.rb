# encoding: utf-8
require 'spec_helper'
require 'date'

describe "Online Scout Manager" do

  describe "Make a DateTime" do
    it "is given a date and a time" do
      Osm::make_datetime(date: '2001-02-03', time: '04:05:06').should == DateTime.new(2001, 02, 03, 04, 05, 06)
    end

    it "is given just a date" do
      Osm::make_datetime(date: '2001-02-03').should == DateTime.new(2001, 02, 03, 00, 00, 00)
      Osm::make_datetime(date: '2001-02-03', time: '').should == DateTime.new(2001, 02, 03, 00, 00, 00)
    end

    it "is given just a time" do
      Osm::make_datetime(time: '01:02:03').should be_nil
      Osm::make_datetime(time: '01:02:03', date: '').should be_nil
    end

    it "is given neither" do
      Osm::make_datetime().should be_nil
      Osm::make_datetime(date: '', time: '').should be_nil
    end

    it "is given an invalid date" do
      Osm::make_datetime(date: 'No date here1', time: '04:05:06').should be_nil
    end

    it "is given an invalid time" do
      Osm::make_datetime(date: '2001-02-03', time: 'No time here!').should be_nil
    end

    it "is given just an invalid date" do
      Osm::make_datetime(date: 'No date here1').should be_nil
    end

    it "is given just an invalid time" do
      Osm::make_datetime(time: 'No time here1').should be_nil
    end

    it "ignores the epoch date if required" do
      Osm.stub(:epoch_date?){ true }
      Osm::make_datetime(date: '1970-01-01', ignore_epoch: true).should be_nil
    end

    it "accepts the epoch date if required" do
      Osm.stub(:epoch_date?){ true }
      Osm::make_datetime(date: '1970-01-01', ignore_epoch: false).should == DateTime.new(1970, 1, 1)
    end
  end


  describe "Parse for a datetime" do
    it "is not given a date" do
      Osm::parse_datetime(nil).should be_nil
      Osm::parse_datetime('').should be_nil
    end

    it "is given a valid datetime" do
      Osm::parse_datetime('2001-02-03 04:05:06').should == DateTime.new(2001, 2, 3, 4, 5, 6)
    end

    it "is given an invalid datetime" do
      Osm::parse_datetime('la;jsndf').should be_nil
    end
  end


  describe "Parse for a date" do
    it "is not given a date" do
      Osm::parse_date(nil).should be_nil
      Osm::parse_date('').should be_nil
    end

    it "is given a valid date string" do
      Osm::parse_date('2001-02-03').should == Date.new(2001, 02, 03)
    end

    it "is given an invalid date string" do
      Osm::parse_date('No date here!').should be_nil
    end

    it "is given a human date" do
      Osm::parse_date('03/02/2001').should == Date.new(2001, 02, 03)
      Osm::parse_date('3/2/2001').should == Date.new(2001, 02, 03)
    end

    it "ignores the epoch date if required" do
      Osm.stub(:epoch_date?){ true }
      Osm::parse_date('1970-01-01', ignore_epoch: true).should be_nil
    end

    it "accepts the epoch date if required" do
      Osm.stub(:epoch_date?){ true }
      Osm::parse_date('1970-01-01', ignore_epoch: false).should == Date.new(1970, 1, 1)
    end

  end


  describe "Check if a date is the epoch" do
    it "given a date" do
      Osm::epoch_date?(Date.new(1970, 1, 1)).should be true
      Osm::epoch_date?(Date.new(2000, 1, 1)).should be false
    end

    it "given a datetime" do
      Osm::epoch_date?(DateTime.new(1970, 1, 1, 3, 4, 5)).should be true
      Osm::epoch_date?(DateTime.new(2000, 1, 1, 3, 4, 5)).should be false
    end

    it "given a string" do
      Osm::epoch_date?('1970-01-01').should be true
      Osm::epoch_date?('2000-01-01').should be false
    end
  end


  describe "Convert to integer or nil" do
    it "given an integer in a string" do
      Osm::to_i_or_nil('1').should == 1
    end

    it "given nil" do
      Osm::to_i_or_nil(nil).should be_nil
    end

    it "given text in a string" do
      Osm::to_i_or_nil('a').should == 0
    end
  end


  describe "Symbolize a hash" do
    it "not given a hash" do
      expect {
        Osm::symbolize_hash("abc")
      }.to raise_error(ArgumentError, 'You did not pass in a hash')
    end

    it "given a hash" do
      hash_in = {
        1 => 1,
        a: 'a',
        'b' => 'b',
      }
      hash_out = {
        '1': 1,
        a: 'a',
        b: 'b',
      }
      Osm::symbolize_hash(hash_in).should == hash_out
    end
  end


  describe "Inspect instance" do

    class TestA < Osm::Model
      attribute :id
      attribute :b
    end
    class TestB < Osm::Model
      attribute :id
      attribute :a
    end

    it "Returns a string" do
      this_one = TestA.new(id: 1, b: '1')
      inspect = Osm.inspect_instance(this_one)
      inspect.should == '#<TestA b: "1", id: 1 >'
    end

    it "Replaces items with their attribute" do
      this_one = TestA.new(id: 1, b: TestB.new(id: 2))
      inspect = Osm.inspect_instance(this_one, options={replace_with: {'b' => :id}})
      inspect.should == '#<TestA b.id: 2, id: 1 >'
    end

  end


  describe "Make permissions Hash" do

    it "Make the hash" do
      from_osm = {
        'badge' => 100,
        'programme' => 20,
        'events' => 10,
      }
      Osm.make_permissions_hash(from_osm).should == {
        badge: [:read, :write, :administer],
        programme: [:read, :write],
        events: [:read],
      }
    end

    it "Includes only relevant permissions" do
      from_osm = {
        't' => true,
        'f' => false,
        'badge' => 100,
      }
      Osm.make_permissions_hash(from_osm).keys.should == [:badge]
    end

  end

end
