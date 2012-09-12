# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Section" do

  class DummyRole
    attr_reader :id
    def initialize(id)
      @id = id
    end
    def <=>(another)
      @id <=> another.id
    end
  end


  before :each do
    @attributes = {
      :id => 1,
      :name => 'Name',
      :subscription_level => :silver,
      :subscription_expires => (Date.today + 60).strftime('%Y-%m-%d'),
      :sectionType => :cubs,
      :numscouts => 10,
      :hasUsedBadgeRecords => true,
      :hasProgramme => true,
      :wizard => false,
      :columnNames => {},
      :fields => {},
      :intouch => {},
      :mobFields => {},
      :extraRecords => [],
      :role => DummyRole.new(1)
    }
  end


  it "Create from API data" do
    data = {
      'subscription_level' => '3',
      'subscription_expires' => (Date.today + 60).strftime('%Y-%m-%d'),
      'sectionType' => 'cubs',
      'numscouts' => 10,
      'columnNames' => {},
      'fields' => {},
      'intouch' => {},
      'mobFields' => {},
      'extraRecords' => [
        {
          'name' => 'Name 1',
          'extraid' => 1
        }, [
          '',
          {
            'name' => 'Name 2',
            'extraid' => 2
          }
        ]
      ]
    }
    role = DummyRole.new(1)
    section = Osm::Section.from_api(1, 'Name', data, role)

    section.id.should == 1
    section.name.should == 'Name' 
    section.subscription_level.should == :gold
    section.subscription_expires.should == Date.today + 60
    section.type.should == :cubs
    section.num_scouts.should == 10
    section.column_names.should == {}
    section.fields.should == {}
    section.intouch_fields.should == {}
    section.mobile_fields.should == {}
    section.flexi_records[0].id.should == 1
    section.flexi_records[0].name.should == 'Name 1'
    section.flexi_records[1].id.should == 2
    section.flexi_records[1].name.should == 'Name 2'
    section.role.should == role

    section.valid?.should be_true
  end

  it "Create has sensible defaults" do
    section = Osm::Section.new

    section.subscription_level.should == :unknown
    section.subscription_expires.should == nil
    section.type.should == :unknown
    section.num_scouts.should == nil
    section.column_names.should == {}
    section.fields.should == {}
    section.intouch_fields.should == {}
    section.mobile_fields.should == {}
    section.flexi_records.should == []
  end


  it "Compares two matching sections" do
    section1 = Osm::Section.new(@attributes)
    section2 = section1.clone

    section1.should == section2
  end

  it "Compares two non-matching sections" do
    section1 = Osm::Section.new(@attributes)
    section2 = Osm::Section.new(@attributes.merge(:id => 2))

    section1.should_not == section2
  end


  it "Sorts by role" do
    section1 = Osm::Section.new(@attributes.merge(:role => DummyRole.new(1)))
    section2 = Osm::Section.new(@attributes.merge(:role => DummyRole.new(2)))

    [section2, section1].sort.should == [section1, section2]
  end


  it "Correctly works out the section type" do
    unknown =   Osm::Section.new(@attributes.merge(:id => 1, :role => DummyRole.new(1)))
    beavers =   Osm::Section.new(@attributes.merge(:id => 2, :type => :beavers, :role => DummyRole.new(2)))
    cubs =      Osm::Section.new(@attributes.merge(:id => 3, :type => :cubs, :role => DummyRole.new(3)))
    scouts =    Osm::Section.new(@attributes.merge(:id => 4, :type => :scouts, :role => DummyRole.new(4)))
    explorers = Osm::Section.new(@attributes.merge(:id => 5, :type => :explorers, :role => DummyRole.new(5)))
    adults =    Osm::Section.new(@attributes.merge(:id => 6, :type => :adults, :role => DummyRole.new(6)))
    waiting =   Osm::Section.new(@attributes.merge(:id => 7, :type => :waiting, :role => DummyRole.new(7)))

    {:beavers => beavers, :cubs => cubs, :scouts => scouts, :explorers => explorers, :adults => adults, :waiting => waiting, :unknwoon => unknown}.each do |section_type, section|
      [:beavers, :cubs, :scouts, :explorers, :adults, :waiting].each do |type|
        section.send("#{type.to_s}?").should == (section_type == type)
      end
    end
  end


  it "Correctly works out if the section is a youth section" do
    unknown =   Osm::Section.new(@attributes.merge(:id => 1, :role => DummyRole.new(1)))
    beavers =   Osm::Section.new(@attributes.merge(:id => 2, :type => :beavers, :role => DummyRole.new(2)))
    cubs =      Osm::Section.new(@attributes.merge(:id => 3, :type => :cubs, :role => DummyRole.new(3)))
    scouts =    Osm::Section.new(@attributes.merge(:id => 4, :type => :scouts, :role => DummyRole.new(4)))
    explorers = Osm::Section.new(@attributes.merge(:id => 5, :type => :explorers, :role => DummyRole.new(5)))
    adults =    Osm::Section.new(@attributes.merge(:id => 6, :type => :adults, :role => DummyRole.new(6)))
    waiting =   Osm::Section.new(@attributes.merge(:id => 7, :type => :waiting, :role => DummyRole.new(7)))

    [beavers, cubs, scouts, explorers].each do |section|
      section.youth_section?.should == true
    end
    [adults, waiting, unknown].each do |section|
      section.youth_section?.should == false
    end
  end

end
