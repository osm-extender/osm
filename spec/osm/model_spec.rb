# encoding: utf-8
require 'spec_helper'


describe "Model" do

  class ModelTester < Osm::Model
    attribute :id
    attribute :data

    def self.test_get_config
      {
        cache: @@cache,
        prepend_to_cache_key: @@prepend_to_cache_key,
        cache_ttl: @@cache_ttl,
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
    expect(model).not_to be_nil
  end


  it "Configure" do
    Osm::Model.configure(
      cache: OsmTest::Cache,
      cache_ttl: 100,
      prepend_to_cache_key: 'Hi'
    )

    config = ModelTester.test_get_config
    expect(config).to eq({
      cache: OsmTest::Cache,
      cache_ttl: 100,
      prepend_to_cache_key: 'Hi',
    })
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
        expect(OsmTest::Cache).to receive('exist?').with("OSMAPI-#{Osm::VERSION}-osm-key") { true }
        expect(ModelTester.cache_exist?(api: $api, key: 'key')).to eq(true)
      end

      it "Without cache" do
        expect(OsmTest::Cache).not_to receive('exist?')
        Osm::Model.cache = nil
        expect(ModelTester.cache_exist?(api: $api, key: 'key')).to eq(false)
      end

      it "Ignoring cache" do
        expect(OsmTest::Cache).not_to receive('exist?')
        expect(ModelTester.cache_exist?(api: $api, key: 'key', no_read_cache: true)).to eq(false)
      end
    end # describe Checks for existance

    describe "Reads" do
      it "With cache" do
        expect(OsmTest::Cache).to receive('read').with("OSMAPI-#{Osm::VERSION}-osm-key") { 'data' }
        expect(ModelTester.cache_read(api: $api, key: 'key')).to eq('data')
      end

      it "Without cache" do
        expect(OsmTest::Cache).not_to receive('read')
        Osm::Model.cache = nil
        expect(ModelTester.cache_read(api: $api, key: 'key')).to eq(nil)
      end

      it "Ignoring cache" do
        expect(OsmTest::Cache).not_to receive('read')
        expect(ModelTester.cache_read(api: $api, key: 'key', no_read_cache: true)).to eq(nil)
      end
    end # describe Reads

    describe "Writes" do
      it "With cache" do
        expect(OsmTest::Cache).to receive('write').with("OSMAPI-#{Osm::VERSION}-osm-key", 'data', {expires_in:600}) { true }
        expect(ModelTester.cache_write(api: $api, key: 'key', data: 'data')).to eq(true)
      end

      it "Without cache" do
        expect(OsmTest::Cache).not_to receive('write')
        Osm::Model.cache = nil
        expect(ModelTester.cache_write(api: $api, key: 'key', data: 'data')).to eq(false)
      end
    end # describe Writes

    describe "Deletes" do
      it "With cache" do
        expect(OsmTest::Cache).to receive('delete').with("OSMAPI-#{Osm::VERSION}-osm-key") { true }
        expect(ModelTester.cache_delete(api: $api, key: 'key')).to eq(true)
      end

      it "Without cache" do
        expect(OsmTest::Cache).not_to receive('delete')
        Osm::Model.cache = nil
        expect(ModelTester.cache_delete(api: $api, key: 'key')).to eq(true)
      end
    end # describe Deletes

    describe "Fetches" do
      it "Without block" do
        expect{ ModelTester.cache_fetch(api: $api, key: 'key') }.to raise_error(ArgumentError, "A block is required")
      end

      it "With cache" do
        block = Proc.new{ "ABC" }
        expect(OsmTest::Cache).to receive('fetch').with("OSMAPI-#{Osm::VERSION}-osm-key", {expires_in:600}).and_yield { "abc" }
        expect(ModelTester.cache_fetch(api: $api, key: 'key', &block)).to eq("ABC")
      end

      it "Without cache" do
        ModelTester.cache = nil
        block = Proc.new{ "GHI" }
        expect(OsmTest::Cache).not_to receive('fetch')
        expect(ModelTester.cache_fetch(api: $api, key: 'key', &block)).to eq("GHI")
      end

      it "Ignoring cache" do
        expect(OsmTest::Cache).not_to receive('read')
        block = Proc.new{ "GHI" }
        expect(ModelTester.cache_fetch(api: $api, key: 'key', no_read_cache: true, &block)).to eq("GHI")
      end
    end # describe fetches

    it "Builds a key from an array" do
      expect(ModelTester.cache_key(api: $api, key: ['a', 'b'])).to eq("OSMAPI-#{Osm::VERSION}-osm-a-b")
    end

  end


  describe "Converts" do
    it "to_i" do
      model = ModelTester.new(id: '123')
      expect(model.to_i).to eq(123)
    end

    describe "to_s" do
      it "when id is an integer" do
        model = ModelTester.new(id: 345)
        expect(model.to_s).to eq("ModelTester with ID: 345")
      end

      it "when id is a string" do
        model = ModelTester.new(id: 'abc')
        expect(model.to_s).to eq('ModelTester with ID: "abc"')
      end
    end
  end # describe Converts


  describe "Get items from ids" do

    it "All items in cache" do
      OsmTest::Cache.write("OSMAPI-#{Osm::VERSION}-osm-items", [1, 2])
      OsmTest::Cache.write("OSMAPI-#{Osm::VERSION}-osm-item-1", '1')
      OsmTest::Cache.write("OSMAPI-#{Osm::VERSION}-osm-item-2", '2')
      expect(ModelTester.test_get_all($api, 'items', 'item')).to eq(['1', '2'])
    end
    
    it "An item not in cache" do
      OsmTest::Cache.write("OSMAPI-#{Osm::VERSION}-osm-items", [1, 2])
      OsmTest::Cache.write("OSMAPI-#{Osm::VERSION}-osm-item-1", '1')
      allow(ModelTester).to receive(:get_all) { ['A', 'B'] }
      expect(ModelTester.test_get_all($api, 'items', 'item')).to eq(['A', 'B'])
    end

  end


  it "Track attribute changes" do
    test = ModelTester.new(id: 1)
    expect(test.id).to eq(1)
    expect(test.changed_attributes).to eq([])

    test.id = 2
    expect(test.changed_attributes).to eq(['id'])

    test.reset_changed_attributes
    expect(test.changed_attributes).to eq([])
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
      expect(@mt1 <=> @mt2).to eq(-1)
      expect(@mt2 <=> @mt1).to eq(1)
      expect(@mt2 <=> @mt2a).to eq(0)
      expect(@mt2a <=> @mt2b).to eq(1)
    end

    it ">" do
      expect(@mt1 > @mt2).to eq(false)
      expect(@mt2 > @mt1).to eq(true)
      expect(@mt2 > @mt2a).to eq(false)
      expect(@mt2a > @mt2b).to eq(true)
    end

    it ">=" do
      expect(@mt1 >= @mt2).to eq(false)
      expect(@mt2 >= @mt1).to eq(true)
      expect(@mt2 >= @mt2a).to eq(true)
      expect(@mt2a >= @mt2b).to eq(true)
    end

    it "<" do
      expect(@mt1 < @mt2).to eq(true)
      expect(@mt2 < @mt1).to eq(false)
      expect(@mt2 < @mt2a).to eq(false)
      expect(@mt2a < @mt2b).to eq(false)
    end

    it "<=" do
      expect(@mt1 <= @mt2).to eq(true)
      expect(@mt2 <= @mt1).to eq(false)
      expect(@mt2 <= @mt2a).to eq(true)
      expect(@mt2a <= @mt2b).to eq(false)
    end

    it "between" do
      expect(@mt2.between?(@mt1, @mt3)).to eq(true)
      expect(@mt1.between?(@mt2, @mt3)).to eq(false)
      expect(@mt3.between?(@mt1, @mt3)).to eq(true)
    end

    it "handles nil" do
      # Sorts by id then -data
      expect(ModelTester.new(id: 1) <=> ModelTester.new).to eq(1)
      expect(ModelTester.new(id: 1, data: 'a') <=> ModelTester.new(id: 1)).to eq(-1)
      expect(ModelTester.new <=> ModelTester.new(id: 1)).to eq(-1)
      expect(ModelTester.new(id: 1) <=> ModelTester.new(id: 1, data: 'a')).to eq(1)
      expect(ModelTester.new <=> ModelTester.new).to eq(0)
     end

  end

  describe "Access control" do

    describe "user_has_permission?" do

      before :each do
        allow($api).to receive(:get_user_permissions).and_return( { 1 => {foo: [:bar]} } )
      end

      it "Has permission" do
        expect(Osm::Model.user_has_permission?(api: $api, to: :bar, on: :foo, section: 1)).to eq(true)
      end

      it "Doesn't have the level of permission" do
        expect(Osm::Model.user_has_permission?(api: $api, to: :barbar, on: :foo, section: 1)).to eq(false)
      end

      it "Doesn't have access to section" do
        expect(Osm::Model.user_has_permission?(api: $api, to: :bar, on: :foo, section: 2)).to eq(false)
      end

    end

    describe "api_has_permission?" do

      before :each do
        allow(Osm::ApiAccess).to receive(:get_ours).and_return(Osm::ApiAccess.new(
          id: $api.api_id,
          name: $api.name,
          permissions: {foo: [:bar]}
        ))
      end

      it "Has permission" do
        expect(Osm::Model.api_has_permission?(api: $api, to: :bar, on: :foo, section: 1)).to eq(true)
      end

      it "Doesn't have the level of permission" do
        expect(Osm::Model.api_has_permission?(api: $api, to: :barbar, on: :foo, section: 1)).to eq(false)
      end

      it "Doesn't have access to the section" do
        allow(Osm::ApiAccess).to receive(:get_ours).and_return(nil)
        expect(Osm::Model.api_has_permission?(api: $api, to: :bar, on: :foo, section: 2)).to eq(false)
      end

    end

    describe "has_permission?" do

      it "Only returns true if the user can and they have granted the api permission" do
        section = Osm::Section.new
        options = {foo: :bar}
        expect(Osm::Model).to receive('user_has_permission?').with(api: $api, to: :can_do, on: :can_to, section: section, **options).and_return(true)
        expect(Osm::Model).to receive('api_has_permission?').with(api: $api, to: :can_do, on: :can_to, section: section, **options).and_return(true)
        expect(Osm::Model.has_permission?(api: $api, to: :can_do, on: :can_to, section: section, **options)).to eq(true)
      end

      describe "Otherwise returns false" do
        [ [true,false], [false, true], [false, false] ].each do |user, api|
          it "User #{user ? 'can' : "can't"} and #{api ? 'has' : "hasn't"} given access" do
            allow(Osm::Model).to receive('user_has_permission?').and_return(user)
            allow(Osm::Model).to receive('api_has_permission?').and_return(api)
            expect(Osm::Model.has_permission?(api: $api, to: :can_do, on: :can_to, section: Osm::Section.new)).to eq(false)
          end
        end
      end

    end

    describe "has_access_to_section?" do

      before :each do
        allow($api).to receive(:get_user_permissions).and_return( {1=>{}} )
      end

      it "Has access" do
        expect(Osm::Model.has_access_to_section?(api: $api, section: 1)).to eq(true)
      end

      it "Doesn't have access" do
        expect(Osm::Model.has_access_to_section?(api: $api, section: 2)).to eq(false)
      end 

    end

    describe "require_access_to_section" do

      before :each do
        allow(Osm::Model).to receive(:require_access_to_section).and_call_original
      end

      it "Does nothing when access is allowed" do
        allow(Osm::Model).to receive('has_access_to_section?') { true }
        expect{ Osm::Model.require_access_to_section(api: $api, section: 5) }.not_to raise_error
      end

      it "Raises exception when access is not allowed" do
        allow(Osm::Model).to receive('has_access_to_section?') { false }
        expect{ Osm::Model.require_access_to_section(api: $api, section: 5) }.to raise_error(Osm::Forbidden, "You do not have access to that section")
      end

    end

    describe "require_permission" do

      it "Does nothing when access is allowed" do
        allow(Osm::Model).to receive('user_has_permission?').and_return(true)
        allow(Osm::Model).to receive('api_has_permission?').and_return(true)
        section = Osm::Section.new(name: 'A SECTION')
        expect{ Osm::Model.require_permission(api: $api, to: :can_do, on: :can_on, section: section) }.not_to raise_error
      end

      it "Raises exception when user doesn't have access" do
        allow(Osm::Model).to receive('user_has_permission?').and_return(false)
        allow(Osm::Model).to receive('api_has_permission?').and_return(true)
        section = Osm::Section.new(name: 'A SECTION')
        expect{ Osm::Model.require_permission(api: $api, to: :can_do, on: :can_on, section: section) }.to raise_error(Osm::Forbidden, "Your OSM user does not have permission to can_do on can_on for A SECTION.")
      end

      it "Raises exception when api doesn't have access" do
        allow(Osm::Model).to receive('user_has_permission?').and_return(true)
        allow(Osm::Model).to receive('api_has_permission?').and_return(false)
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
        allow(Osm::Model).to receive(:require_ability_to).and_call_original
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
          allow(Osm::Model).to receive(:require_permission).and_return(nil)
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
