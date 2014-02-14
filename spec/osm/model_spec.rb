# encoding: utf-8
require 'spec_helper'


describe "Model" do

  class ModelTester < Osm::Model
    attribute :id
    attr_accessible :id if ActiveModel::VERSION::MAJOR < 4

    def self.test_get_config
      {
        :cache => @@cache,
        :prepend_to_key => @@cache_prepend,
        :ttl => @@cache_ttl,
      }
    end

    def self.cache(method, *options)
      self.send("cache_#{method}", *options)
    end

    def self.test_get_all(api, keys, key)
      ids = cache_read(api, keys)
      return get_from_ids(api, ids, key, {}, :get_all)
    end
  end


  it "Create" do
    model = Osm::Model.new
    model.should_not be_nil
  end


  it "Configure" do
    options = {
      :cache => OsmTest::Cache,
      :ttl => 100,
      :prepend_to_key => 'Hi',
    }

    Osm::Model.configure(options)
    config = ModelTester.test_get_config
    config.should == options
  end

  it "Configure (allows empty Hash)" do
    Osm::Model.configure({})
    config = ModelTester.test_get_config
    config[:cache].should be_nil
    config[:ttl].should == 600
    config[:prepend_to_key].should == 'OSMAPI'
  end

  it "Configure (bad arguments)" do
    expect{ Osm::Model.configure(@CONFIGURATION[:cache].merge(:prepend_to_key => :invalid)) }.to raise_error(ArgumentError, ':prepend_to_key must be a String')

    expect{ Osm::Model.configure(@CONFIGURATION[:cache].merge(:ttl => :invalid)) }.to raise_error(ArgumentError, ':ttl must be a FixNum greater than 0')
    expect{ Osm::Model.configure(@CONFIGURATION[:cache].merge(:ttl => 0)) }.to raise_error(ArgumentError, ':ttl must be a FixNum greater than 0')

    expect{ Osm::Model.configure(@CONFIGURATION[:cache].merge(:cache => String)) }.to raise_error(ArgumentError, ':cache must have a exist? method')
  end


  describe "Caching" do

    it "Checks for existance" do
      OsmTest::Cache.should_receive('exist?').with('OSMAPI-osm-key') { true }
      ModelTester.cache('exist?', @api, 'key').should be_true
    end

    it "Writes" do
      OsmTest::Cache.should_receive('write').with('OSMAPI-osm-key', 'data', {:expires_in=>600}) { true }
      ModelTester.cache('write', @api, 'key', 'data').should be_true
    end

    it "Reads" do
      OsmTest::Cache.should_receive('read').with('OSMAPI-osm-key') { 'data' }
      ModelTester.cache('read', @api, 'key').should == 'data'
    end

    it "Deletes" do
      OsmTest::Cache.should_receive('delete').with('OSMAPI-osm-key') { true }
      ModelTester.cache('delete', @api, 'key').should be_true
    end

    it "Behaves when cache is nil (no caching)" do
      Osm::Model.configure({:cache => nil})
      ModelTester.cache('exist?', @api, 'key').should be_false
      ModelTester.cache('write', @api, 'key', 'data').should be_false
      ModelTester.cache('read', @api, 'key').should be_nil
      ModelTester.cache('delete', @api, 'key').should be_true
    end

    it "Builds a key from an array" do
      ModelTester.cache('key', @api, ['a', 'b']).should == 'OSMAPI-osm-a-b'
    end

  end


  describe "Get items from ids" do

    it "All items in cache" do
      OsmTest::Cache.write('OSMAPI-osm-items', [1, 2])
      OsmTest::Cache.write('OSMAPI-osm-item-1', '1')
      OsmTest::Cache.write('OSMAPI-osm-item-2', '2')
      ModelTester.test_get_all(@api, 'items', 'item').should == ['1', '2']
    end
    
    it "An item not in cache" do
      OsmTest::Cache.write('OSMAPI-osm-items', [1, 2])
      OsmTest::Cache.write('OSMAPI-osm-item-1', '1')
      ModelTester.stub(:get_all) { ['A', 'B'] }
      ModelTester.test_get_all(@api, 'items', 'item').should == ['A', 'B']
    end

  end


  describe "Track attribute changes" do
    test = ModelTester.new(:id => 1)
    test.id.should == 1
    test.changed_attributes.should == []

    test.id = 2
    test.changed_attributes.should == ['id']

    test.reset_changed_attributes
    test.changed_attributes.should == []
  end


  describe "Comparisons" do

    before :each do
      @mt1 = ModelTester.new(:id => 1)
      @mt2 = ModelTester.new(:id => 2)
      @mt3 = ModelTester.new(:id => 3)
      @mt2a = ModelTester.new(:id => 2)
    end

    it "<=>" do
      (@mt1 <=> @mt2).should == -1
      (@mt2 <=> @mt1).should == 1
      (@mt2 <=> @mt2a).should == 0
    end

    it ">" do
      (@mt1 > @mt2).should be_false
      (@mt2 > @mt1).should be_true
      (@mt2 > @mt2a).should be_false
    end

    it ">=" do
      (@mt1 >= @mt2).should be_false
      (@mt2 >= @mt1).should be_true
      (@mt2 >= @mt2a).should be_true
    end

    it "<" do
      (@mt1 < @mt2).should be_true
      (@mt2 < @mt1).should be_false
      (@mt2 < @mt2a).should be_false
    end

    it "<=" do
      (@mt1 <= @mt2).should be_true
      (@mt2 <= @mt1).should be_false
      (@mt2 <= @mt2a).should be_true
    end

    it "between" do
      @mt2.between?(@mt1, @mt3).should be_true
      @mt1.between?(@mt1, @mt3).should be_false
      @mt3.between?(@mt1, @mt3).should be_false
    end

  end

end
