# encoding: utf-8
require 'spec_helper'


describe "Model" do

  class ModelTester < Osm::Model
    attribute :id
    attribute :data

    def self.test_get_config
      {
        :cache => @@cache,
        :prepend_to_cache_key => @@prepend_to_cache_key,
        :cache_ttl => @@cache_ttl,
      }
    end

    def self.test_get_all(api, keys, key)
      ids = cache_read(api: api, key: keys)
      return get_from_ids(api: api, ids: ids, key_base: key, method: :get_all)
    end

    protected def sort_by
      ['id', '-data']
    end
  end


  it "Create" do
    model = Osm::Model.new
    model.should_not be_nil
  end


  it "Configure" do
    Osm::Model.configure(
      cache: OsmTest::Cache,
      cache_ttl: 100,
      prepend_to_cache_key: 'Hi'
    )

    config = ModelTester.test_get_config
    config.should == {
      :cache => OsmTest::Cache,
      :cache_ttl => 100,
      :prepend_to_cache_key => 'Hi',
    }
  end

  it "Configure (bad arguments)" do
    expect{ Osm::Model.configure(prepend_to_cache_key: :invalid) }.to raise_error(ArgumentError, 'prepend_to_cache_key must be a String')

    expect{ Osm::Model.configure(cache_ttl: :invalid) }.to raise_error(ArgumentError, 'cache_ttl must be a FixNum greater than 0')
    expect{ Osm::Model.configure(cache_ttl: 0) }.to raise_error(ArgumentError, 'cache_ttl must be a FixNum greater than 0')

    expect{ Osm::Model.configure(cache: String) }.to raise_error(ArgumentError, 'cache must have a exist? method')
  end


  describe "Caching" do

    describe "Checks for existance" do
      it "With cache" do
        OsmTest::Cache.should_receive('exist?').with("OSMAPI-#{Osm::VERSION}-osm-key") { true }
        ModelTester.cache_exist?(api: $api, key: 'key').should == true
      end

      it "Without cache" do
        OsmTest::Cache.should_not_receive('exist?')
        Osm::Model.cache = nil
        ModelTester.cache_exist?(api: $api, key: 'key').should == false
      end

      it "Ignoring cache" do
        OsmTest::Cache.should_not_receive('exist?')
        ModelTester.cache_exist?(api: $api, key: 'key', no_read_cache: true).should == false
      end
    end # describe Checks for existance

    describe "Reads" do
      it "With cache" do
        OsmTest::Cache.should_receive('read').with("OSMAPI-#{Osm::VERSION}-osm-key") { 'data' }
        ModelTester.cache_read(api: $api, key: 'key').should == 'data'
      end

      it "Without cache" do
        OsmTest::Cache.should_not_receive('read')
        Osm::Model.cache = nil
        ModelTester.cache_read(api: $api, key: 'key').should == nil
      end

      it "Ignoring cache" do
        OsmTest::Cache.should_not_receive('read')
        ModelTester.cache_read(api: $api, key: 'key', no_read_cache: true).should == nil
      end
    end # describe Reads

    describe "Writes" do
      it "With cache" do
        OsmTest::Cache.should_receive('write').with("OSMAPI-#{Osm::VERSION}-osm-key", 'data', {:expires_in=>600}) { true }
        ModelTester.cache_write(api: $api, key: 'key', data: 'data').should == true
      end

      it "Without cache" do
        OsmTest::Cache.should_not_receive('write')
        Osm::Model.cache = nil
        ModelTester.cache_write(api: $api, key: 'key', data: 'data').should == false
      end
    end # describe Writes

    describe "Deletes" do
      it "With cache" do
        OsmTest::Cache.should_receive('delete').with("OSMAPI-#{Osm::VERSION}-osm-key") { true }
        ModelTester.cache_delete(api: $api, key: 'key').should == true
      end

      it "Without cache" do
        OsmTest::Cache.should_not_receive('delete')
        Osm::Model.cache = nil
        ModelTester.cache_delete(api: $api, key: 'key').should == true
      end
    end # describe Deletes

    describe "Fetches" do
      it "Without block" do
        expect{ ModelTester.cache_fetch(api: $api, key: 'key') }.to raise_error(ArgumentError, "A block is required")
      end

      it "With cache" do
        block = Proc.new{ "ABC" }
        OsmTest::Cache.should_receive('fetch').with("OSMAPI-#{Osm::VERSION}-osm-key", {:expires_in=>600}).and_yield { "abc" }
        ModelTester.cache_fetch(api: $api, key: 'key', &block).should == "ABC"
      end

      it "Without cache" do
        ModelTester.cache = nil
        block = Proc.new{ "GHI" }
        OsmTest::Cache.should_not_receive('fetch')
        ModelTester.cache_fetch(api: $api, key: 'key', &block).should == "GHI"
      end

      it "Ignoring cache" do
        OsmTest::Cache.should_not_receive('read')
        block = Proc.new{ "GHI" }
        ModelTester.cache_fetch(api: $api, key: 'key', no_read_cache: true, &block).should == "GHI"
      end
    end # describe fetches

    it "Builds a key from an array" do
      ModelTester.cache_key(api: $api, key: ['a', 'b']).should == "OSMAPI-#{Osm::VERSION}-osm-a-b"
    end

  end


  describe "Converts" do
    it "to_i" do
      model = ModelTester.new(id: '123')
      model.to_i.should == 123
    end

    describe "to_s" do
      it "when id is an integer" do
        model = ModelTester.new(id: 345)
        model.to_s.should == "ModelTester with ID: 345"
      end

      it "when id is a string" do
        model = ModelTester.new(id: 'abc')
        model.to_s.should == 'ModelTester with ID: "abc"'
      end
    end
  end # describe Converts


  describe "Get items from ids" do

    it "All items in cache" do
      OsmTest::Cache.write("OSMAPI-#{Osm::VERSION}-osm-items", [1, 2])
      OsmTest::Cache.write("OSMAPI-#{Osm::VERSION}-osm-item-1", '1')
      OsmTest::Cache.write("OSMAPI-#{Osm::VERSION}-osm-item-2", '2')
      ModelTester.test_get_all($api, 'items', 'item').should == ['1', '2']
    end
    
    it "An item not in cache" do
      OsmTest::Cache.write("OSMAPI-#{Osm::VERSION}-osm-items", [1, 2])
      OsmTest::Cache.write("OSMAPI-#{Osm::VERSION}-osm-item-1", '1')
      ModelTester.stub(:get_all) { ['A', 'B'] }
      ModelTester.test_get_all($api, 'items', 'item').should == ['A', 'B']
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
      @mt1 = ModelTester.new(id: 1, data: 'a')
      @mt2 = ModelTester.new(id: 2, data: 'a')
      @mt3 = ModelTester.new(id: 3, data: 'a')
      @mt2a = ModelTester.new(id: 2, data: 'a')
      @mt2b = ModelTester.new(id: 2, data: 'b')
    end

    it "<=>" do
      (@mt1 <=> @mt2).should == -1
      (@mt2 <=> @mt1).should == 1
      (@mt2 <=> @mt2a).should == 0
      (@mt2a <=> @mt2b).should == 1
    end

    it ">" do
      (@mt1 > @mt2).should == false
      (@mt2 > @mt1).should == true
      (@mt2 > @mt2a).should == false
      (@mt2a > @mt2b).should == true
    end

    it ">=" do
      (@mt1 >= @mt2).should == false
      (@mt2 >= @mt1).should == true
      (@mt2 >= @mt2a).should == true
      (@mt2a >= @mt2b).should == true
    end

    it "<" do
      (@mt1 < @mt2).should == true
      (@mt2 < @mt1).should == false
      (@mt2 < @mt2a).should == false
      (@mt2a < @mt2b).should == false
    end

    it "<=" do
      (@mt1 <= @mt2).should == true
      (@mt2 <= @mt1).should == false
      (@mt2 <= @mt2a).should == true
      (@mt2a <= @mt2b).should == false
    end

    it "between" do
      @mt2.between?(@mt1, @mt3).should == true
      @mt1.between?(@mt2, @mt3).should == false
      @mt3.between?(@mt1, @mt3).should == true
    end

    it "handles nil" do
      # Sorts by id then -data
      (ModelTester.new(id: 1) <=> ModelTester.new).should == 1
      (ModelTester.new(id: 1, data: 'a') <=> ModelTester.new(id: 1)).should == -1
      (ModelTester.new <=> ModelTester.new(id: 1)).should == -1
      (ModelTester.new(id: 1) <=> ModelTester.new(id: 1, data: 'a')).should == 1
      (ModelTester.new <=> ModelTester.new).should == 0
     end

  end

  describe "Access control" do

    describe "user_has_permission?" do

      before :each do
        $api.stub(:get_user_permissions).and_return( { 1 => {foo: [:bar]} } )
      end

      it "Has permission" do
        Osm::Model.user_has_permission?(api: $api, to: :bar, on: :foo, section: 1).should == true
      end

      it "Doesn't have the level of permission" do
        Osm::Model.user_has_permission?(api: $api, to: :barbar, on: :foo, section: 1).should == false
      end

      it "Doesn't have access to section" do
        Osm::Model.user_has_permission?(api: $api, to: :bar, on: :foo, section: 2).should == false
      end

    end

    describe "api_has_permission?" do

      before :each do
        Osm::ApiAccess.stub(:get_ours).and_return(Osm::ApiAccess.new(
          id: $api.api_id,
          name: $api.name,
          permissions: {foo: [:bar]}
        ))
      end

      it "Has permission" do
        Osm::Model.api_has_permission?(api: $api, to: :bar, on: :foo, section: 1).should == true
      end

      it "Doesn't have the level of permission" do
        Osm::Model.api_has_permission?(api: $api, to: :barbar, on: :foo, section: 1).should == false
      end

      it "Doesn't have access to the section" do
        Osm::ApiAccess.stub(:get_ours).and_return(nil)
        Osm::Model.api_has_permission?(api: $api, to: :bar, on: :foo, section: 2).should == false
      end

    end

    describe "has_permission?" do

      it "Only returns true if the user can and they have granted the api permission" do
        section = Osm::Section.new
        options = {:foo => :bar}
        expect(Osm::Model).to receive('user_has_permission?').with(api: $api, to: :can_do, on: :can_to, section: section, **options).and_return(true)
        expect(Osm::Model).to receive('api_has_permission?').with(api: $api, to: :can_do, on: :can_to, section: section, **options).and_return(true)
        Osm::Model.has_permission?(api: $api, to: :can_do, on: :can_to, section: section, **options).should == true
      end

      describe "Otherwise returns false" do
        [ [true,false], [false, true], [false, false] ].each do |user, api|
          it "User #{user ? 'can' : "can't"} and #{api ? 'has' : "hasn't"} given access" do
            Osm::Model.stub('user_has_permission?').and_return(user)
            Osm::Model.stub('api_has_permission?').and_return(api)
            Osm::Model.has_permission?(api: $api, to: :can_do, on: :can_to, section: Osm::Section.new).should == false
          end
        end
      end

    end

    describe "has_access_to_section?" do

      before :each do
        $api.stub(:get_user_permissions).and_return( {1=>{}} )
      end

      it "Has access" do
        Osm::Model.has_access_to_section?(api: $api, section: 1).should == true
      end

      it "Doesn't have access" do
        Osm::Model.has_access_to_section?(api: $api, section: 2).should == false
      end 

    end

    describe "require_access_to_section" do

      before :each do
        Osm::Model.unstub(:require_access_to_section)
      end

      it "Does nothing when access is allowed" do
        Osm::Model.stub('has_access_to_section?') { true }
        expect{ Osm::Model.require_access_to_section(api: $api, section: 5) }.not_to raise_error
      end

      it "Raises exception when access is not allowed" do
        Osm::Model.stub('has_access_to_section?') { false }
        expect{ Osm::Model.require_access_to_section(api: $api, section: 5) }.to raise_error(Osm::Forbidden, "You do not have access to that section")
      end

    end

    describe "require_permission" do

      it "Does nothing when access is allowed" do
        Osm::Model.stub('user_has_permission?').and_return(true)
        Osm::Model.stub('api_has_permission?').and_return(true)
        section = Osm::Section.new(name: 'A SECTION')
        expect{ Osm::Model.require_permission(api: $api, to: :can_do, on: :can_on, section: section) }.not_to raise_error
      end

      it "Raises exception when user doesn't have access" do
        Osm::Model.stub('user_has_permission?').and_return(false)
        Osm::Model.stub('api_has_permission?').and_return(true)
        section = Osm::Section.new(name: 'A SECTION')
        expect{ Osm::Model.require_permission(api: $api, to: :can_do, on: :can_on, section: section) }.to raise_error(Osm::Forbidden, "Your OSM user does not have permission to can_do on can_on for A SECTION.")
      end

      it "Raises exception when api doesn't have access" do
        Osm::Model.stub('user_has_permission?').and_return(true)
        Osm::Model.stub('api_has_permission?').and_return(false)
        section = Osm::Section.new(name: 'A SECTION')
        expect{ Osm::Model.require_permission(api: $api, to: :can_do, on: :can_on, section: section) }.to raise_error(Osm::Forbidden, "You have not granted the can_do permissions on can_on to the API NAME API for A SECTION.")
      end

    end

    describe "require_subscription" do

      it "Checks against a number" do
        section1 = Osm::Section.new(subscription_level: 1, name: 'NAME') # Bronze
        section2 = Osm::Section.new(subscription_level: 2, name: 'NAME') # Silver
        section3 = Osm::Section.new(subscription_level: 3, name: 'NAME') # Gold
        section4 = Osm::Section.new(subscription_level: 4, name: 'NAME') # Gold+

        expect{ Osm::Model.require_subscription(api: $api, level: 1, section: section1) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: 2, section: section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Silver required for NAME).")
        expect{ Osm::Model.require_subscription(api: $api, level: 3, section: section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold required for NAME).")
        expect{ Osm::Model.require_subscription(api: $api, level: 4, section: section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(api: $api, level: 1, section: section2) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: 2, section: section2) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: 3, section: section2) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold required for NAME).")
        expect{ Osm::Model.require_subscription(api: $api, level: 4, section: section2) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(api: $api, level: 1, section: section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: 2, section: section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: 3, section: section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: 4, section: section3) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(api: $api, level: 1, section: section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: 2, section: section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: 3, section: section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: 4, section: section4) }.not_to raise_error
      end

      it "Checks against a symbol" do
        section1 = Osm::Section.new(subscription_level: 1, name: 'NAME') # Bronze
        section2 = Osm::Section.new(subscription_level: 2, name: 'NAME') # Silver
        section3 = Osm::Section.new(subscription_level: 3, name: 'NAME') # Gold
        section4 = Osm::Section.new(subscription_level: 4, name: 'NAME') # Gold+

        expect{ Osm::Model.require_subscription(api: $api, level: :bronze, section: section1) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: :silver, section: section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Silver required for NAME).")
        expect{ Osm::Model.require_subscription(api: $api, level: :gold, section: section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold required for NAME).")
        expect{ Osm::Model.require_subscription(api: $api, level: :gold_plus, section: section1) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(api: $api, level: :bronze, section: section2) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: :silver, section: section2) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: :gold, section: section2) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold required for NAME).")
        expect{ Osm::Model.require_subscription(api: $api, level: :gold_plus, section: section2) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(api: $api, level: :bronze, section: section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: :silver, section: section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: :gold, section: section3) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: :gold_plus, section: section3) }.to raise_error(Osm::Forbidden, "Insufficent OSM subscription level (Gold+ required for NAME).")

        expect{ Osm::Model.require_subscription(api: $api, level: :bronze, section: section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: :silver, section: section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: :gold, section: section4) }.not_to raise_error
        expect{ Osm::Model.require_subscription(api: $api, level: :gold_plus, section: section4) }.not_to raise_error
      end

    end

    describe "Require_abillity_to" do

      before :each do
        Osm::Model.unstub(:require_ability_to)
      end

      it "Requires permission" do
        section = Osm::Section.new(type: :waiting)
        options = {foo: 'bar'}
        expect(Osm::Model).to receive(:require_permission).with(api: $api, to: :can_do, on: :can_on, section: section, **options).and_return(true)
        expect(Osm::Model).not_to receive(:require_subscription)
        expect{ Osm::Model.require_ability_to(api: $api, to: :can_do, on: :can_on, section: section, **options) }.not_to raise_error
      end

      describe "Requires the right subscription level for" do

        before :each do
          @section = Osm::Section.new(type: :beavers)
          @options = {bar: 'foo'}
          Osm::Model.stub(:require_permission).and_return(nil)
        end

        [:register, :contact, :events, :flexi].each do |can_on|
          it ":#{can_on.to_s} (Silver)" do
            expect(Osm::Model).to receive(:require_subscription).with(api: $api, level: :silver, section: @section, **@options).and_return(true)
            expect{ Osm::Model.require_ability_to(api: $api, to: :read, on: can_on, section: @section, **@options) }.to_not raise_error
          end
        end

        [:finance].each do |can_on|
          it ":#{can_on.to_s} (Gold)" do
            expect(Osm::Model).to receive(:require_subscription).with(api: $api, level: :gold, section: @section, **@options).and_return(true)
            expect{ Osm::Model.require_ability_to(api: $api, to: :read, on: can_on, section: @section, **@options) }.to_not raise_error
          end
        end

      end

    end

  end

end
