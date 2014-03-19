# encoding: utf-8
require 'spec_helper'
require 'date'

describe "Online Scout Manager" do

  describe "Make array of symbols" do
    it "turns array of strings to an array of symbols" do
      start = %w{first second third}
      Osm::make_array_of_symbols(start).should == [:first, :second, :third]
    end
  end


  describe "Make a DateTime" do
    it "is given a date and a time" do
      Osm::make_datetime('2001-02-03', '04:05:06').should == DateTime.new(2001, 02, 03, 04, 05, 06)
    end

    it "is given just a date" do
      Osm::make_datetime('2001-02-03', '').should == DateTime.new(2001, 02, 03, 00, 00, 00)
    end

    it "is given neither" do
      Osm::make_datetime('', '').should be_nil
    end

    it "is given an invalid date" do
      Osm::make_datetime('No date here1', '04:05:06').should be_nil
    end

    it "is given an invalid time" do
      Osm::make_datetime('2001-02-03', 'No time here!').should be_nil
    end

    it "is given just an invalid date" do
      Osm::make_datetime('No date here1', nil).should be_nil
    end
  end


  describe "Parse a date" do
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

  end


  describe "Inspect instance" do

    class TestA < Osm::Model
      attribute :id
      attribute :b
      attr_accessible :id, :b if ActiveModel::VERSION::MAJOR < 4
    end
    class TestB < Osm::Model
      attribute :id
      attribute :a
      attr_accessible :id, :a if ActiveModel::VERSION::MAJOR < 4
    end

    it "Returns a string" do
      this_one = TestA.new(:id => 1, :b => '1')
      inspect = Osm.inspect_instance(this_one)
      inspect.should == '#<TestA b: "1", id: 1 >'
    end

    it "Replaces items with their attribute" do
      this_one = TestA.new(:id => 1, :b => TestB.new(:id => 2))
      inspect = Osm.inspect_instance(this_one, options={:replace_with => {'b' => :id}})
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
        :badge => [:read, :write, :administer],
        :programme => [:read, :write],
        :events => [:read],
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
