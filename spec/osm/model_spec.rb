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

  describe "Access control" do

    describe "user_has_permission?" do

      before :each do
        @api.stub(:get_user_permissions).and_return( { 1 => {foo: [:bar]} } )
      end

      it "Has permission" do
        Osm::Model.user_has_permission?(@api, :bar, :foo, 1).should be_true
      end

      it "Doesn't have the level of permission" do
        Osm::Model.user_has_permission?(@api, :barbar, :foo, 1).should be_false
      end

      it "Doesn't have access to section" do
        Osm::Model.user_has_permission?(@api, :bar, :foo, 2).should be_false
      end

    end

    describe "api_has_permission?" do

      before :each do
        Osm::ApiAccess.stub(:get_ours).and_return(Osm::ApiAccess.new(
          id: @api.api_id,
          name: @api.api_name,
          permissions: {foo: [:bar]}
        ))
      end

      it "Has permission" do
        Osm::Model.api_has_permission?(@api, :bar, :foo, 1).should be_true
      end

      it "Doesn't have the level of permission" do
        Osm::Model.api_has_permission?(@api, :barbar, :foo, 1).should be_false
      end

      it "Doesn't have access to the section" do
        Osm::ApiAccess.stub(:get_ours).and_return(nil)
        Osm::Model.api_has_permission?(@api, :bar, :foo, 2).should be_false
      end

    end

    describe "has_permission?" do

      it "Only returns true if the user can and they have granted the api permission" do
        section = Osm::Section.new
        options = {:foo => :bar}
        expect(Osm::Model).to receive('user_has_permission?').with(@api, :can_do, :can_to, section, options).and_return(true)
        expect(Osm::Model).to receive('api_has_permission?').with(@api, :can_do, :can_to, section, options).and_return(true)
        Osm::Model.has_permission?(@api, :can_do, :can_to, section, options).should be_true
      end

      describe "Otherwise returns false" do
        [ [true,false], [false, true], [false, false] ].each do |user, api|
          it "User #{user ? 'can' : "can't"} and #{api ? 'has' : "hasn't"} given access" do
            Osm::Model.stub('user_has_permission?').and_return(user)
            Osm::Model.stub('api_has_permission?').and_return(api)
            Osm::Model.has_permission?(@api, :can_do, :can_to, Osm::Section.new).should be_false
          end
        end
      end

    end

    describe "has_access_to_section?" do

      before :each do
        @api.stub(:get_user_permissions).and_return( {1=>{}} )
      end

      it "Has access" do
        Osm::Model.has_access_to_section?(@api, 1).should be_true
      end

      it "Doesn't have access" do
        Osm::Model.has_access_to_section?(@api, 2).should be_false
      end 

    end

    describe "require_access_to_section" do

      before :each do
        Osm::Model.unstub(:require_access_to_section)
      end

      it "Does nothing when access is allowed" do
        Osm::Model.stub('has_access_to_section?') { true }
        expect{ Osm::Model.require_access_to_section(@api, 1) }.not_to raise_error
      end

      it "Raises exception when access is not allowed" do
        Osm::Model.stub('has_access_to_section?') { false }
        expect{ Osm::Model.require_access_to_section(@api, 1) }.to raise_error(Osm::Forbidden, "You do not have access to that section")
      end

    end

    describe "require_permission" do

      it "Does nothing when access is allowed" do
        Osm::Model.stub('user_has_permission?').and_return(true)
        Osm::Model.stub('api_has_permission?').and_return(true)
        section = Osm::Section.new(name: 'A SECTION')
        expect{ Osm::Model.require_permission(@api, :to, :on, section) }.not_to raise_error
      end

      it "Raises exception when user doesn't have access" do
        Osm::Model.stub('user_has_permission?').and_return(false)
        Osm::Model.stub('api_has_permission?').and_return(true)
        section = Osm::Section.new(name: 'A SECTION')
        expect{ Osm::Model.require_permission(@api, :can_do, :can_on, section) }.to raise_error(Osm::Forbidden, "Your OSM user does not have permission to can_do on can_on for A SECTION.")
      end

      it "Raises exception when api doesn't have access" do
        Osm::Model.stub('user_has_permission?').and_return(true)
        Osm::Model.stub('api_has_permission?').and_return(false)
        section = Osm::Section.new(name: 'A SECTION')
        expect{ Osm::Model.require_permission(@api, :can_to, :can_on, section) }.to raise_error(Osm::Forbidden, "You have not granted the can_to permissions on can_on to the API NAME API for A SECTION.")
      end

    end

    describe "require_subscription" do

      it "Checks against a number" do
        section1 = Osm::Section.new(subscription_level: 1, name: 'NAME') # Bronze
        section2 = Osm::Section.new(subscription_level: 2, name: 'NAME') # Silver
        section3 = Osm::Section.new(subscription_level: 3, name: 'NAME') # Gold
        section4 = Osm::Section.new(subscription_level: 4, name: 'NAME') # Gold+

        expect{ Osm::Model.require_subscription(@api, 1, section1) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, 2, section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Silver required for NAME).")
        expect{ Osm::Model.require_subscription(@api, 3, section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold required for NAME).")
        expect{ Osm::Model.require_subscription(@api, 4, section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(@api, 1, section2) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, 2, section2) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, 3, section2) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold required for NAME).")
        expect{ Osm::Model.require_subscription(@api, 4, section2) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(@api, 1, section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, 2, section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, 3, section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, 4, section3) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(@api, 1, section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, 2, section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, 3, section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, 4, section4) }.not_to raise_error
      end

      it "Checks against a symbol" do
        section1 = Osm::Section.new(subscription_level: 1, name: 'NAME') # Bronze
        section2 = Osm::Section.new(subscription_level: 2, name: 'NAME') # Silver
        section3 = Osm::Section.new(subscription_level: 3, name: 'NAME') # Gold
        section4 = Osm::Section.new(subscription_level: 4, name: 'NAME') # Gold+

        expect{ Osm::Model.require_subscription(@api, :bronze, section1) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, :silver, section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Silver required for NAME).")
        expect{ Osm::Model.require_subscription(@api, :gold, section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold required for NAME).")
        expect{ Osm::Model.require_subscription(@api, :gold_plus, section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(@api, :bronze, section2) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, :silver, section2) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, :gold, section2) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold required for NAME).")
        expect{ Osm::Model.require_subscription(@api, :gold_plus, section2) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(@api, :bronze, section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, :silver, section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, :gold, section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, :gold_plus, section3) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(@api, :bronze, section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, :silver, section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, :gold, section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(@api, :gold_plus, section4) }.not_to raise_error
      end

    end

    describe "Require_abillity_to" do

      before :each do
        Osm::Model.unstub(:require_ability_to)
      end

      it "Requires permission" do
        section = Osm::Section.new(type: :waiting)
        options = {foo: 'bar'}
        expect(Osm::Model).to receive(:require_permission).with(@api, :can_do, :can_on, section, options).and_return(true)
        expect(Osm::Model).not_to receive(:require_subscription)
        expect{ Osm::Model.require_ability_to(@api, :can_do, :can_on, section, options) }.not_to raise_error
      end

      describe "Requires the right subscription level for" do

        before :each do
          @section = Osm::Section.new(type: :beavers)
          @options = {bar: 'foo'}
          Osm::Model.stub(:require_permission).and_return(nil)
        end

        [:register, :contact, :events, :flexi].each do |can_on|
          it ":#{can_on.to_s} (Silver)" do
            expect(Osm::Model).to receive(:require_subscription).with(@api, :silver, @section, @options).and_return(true)
            expect{ Osm::Model.require_ability_to(@api, :read, can_on, @section, @options) }.to_not raise_error
          end
        end

        [:finance].each do |can_on|
          it ":#{can_on.to_s} (Gold)" do
            expect(Osm::Model).to receive(:require_subscription).with(@api, :gold, @section, @options).and_return(true)
            expect{ Osm::Model.require_ability_to(@api, :read, can_on, @section, @options) }.to_not raise_error
          end
        end

      end

    end

  end

end
