# encoding: utf-8
require 'spec_helper'
require 'date'

describe "Term" do

  before :each do
    @attributes = {
      :id => 1,
      :section_id => 2,
      :name => 'Term name',
      :start => Date.new(2001, 01, 01),
      :finish => Date.new(2001, 03, 31)
    }
  end

  it "Create from API data" do
    data = {
      'termid' => '1',
      'sectionid' => '2',
      'name' => 'Term name',
      'startdate' => '2001-01-01',
      'enddate' => '2001-03-31'
    }
    term = Osm::Term.from_api(data)

    term.id.should == 1
    term.section_id.should == 2
    term.name.should == 'Term name'
    term.start.should == Date.new(2001, 1, 1)
    term.finish.should == Date.new(2001, 3, 31)
  end


  it "Compares two matching terms" do
    term1 = Osm::Term.new(@attributes)
    term2 = Osm::Term.new(@attributes)
    term1.should == term2
  end

  it "Compares two non-matching terms" do
    term = Osm::Term.new(@attributes)

    term.should_not == Osm::Term.new(@attributes.merge(:id => 3))
  end


  it "Sorts by Section ID, Start date and then Term ID" do
    term1 = Osm::Term.new(@attributes.merge(:section_id => 1, :term => 11, :start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:section_id => 1, :term => 12, :start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:section_id => 1, :term => 13, :start => (Date.today +  1), :finish => (Date.today + 60)))
    term4 = Osm::Term.new(@attributes.merge(:section_id => 2, :term => 1, :start => (Date.today +  1), :finish => (Date.today + 60)))
    term5 = Osm::Term.new(@attributes.merge(:section_id => 2, :term => 2, :start => (Date.today +  1), :finish => (Date.today + 60)))

    data = [term5, term3, term2, term4, term1]
    data.sort.should == [term1, term2, term3, term4, term5]
  end


  it "Works out if it is completly before a date" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.before?(Date.today).should == true
    term2.before?(Date.today).should == false
    term3.before?(Date.today).should == false
  end


  it "Works out if it is completly after a date" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.after?(Date.today).should == false
    term2.after?(Date.today).should == false
    term3.after?(Date.today).should == true
  end


  it "Works out if it has passed" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.past?().should == true
    term2.past?().should == false
    term3.past?().should == false
  end


  it "Works out if it is in the future" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.future?().should == false
    term2.future?().should == false
    term3.future?().should == true
  end


  it "Works out if it is the current term" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start=> (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.current?().should == false
    term2.current?().should == true
    term3.current?().should == false
  end


  it "Works out if it contains a date" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.contains_date?(Date.today).should == false
    term2.contains_date?(Date.today).should == true
    term3.contains_date?(Date.today).should == false
  end

end
