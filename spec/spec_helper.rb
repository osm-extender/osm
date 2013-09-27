require 'fakeweb'
require 'httparty'
require 'active_support'
require 'active_attr/rspec'
require 'active_model'

require 'osm'

FakeWeb.allow_net_connect = false


RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.before(:each) do
    FakeWeb.clean_registry
    OsmTest::Cache.clear

    @CONFIGURATION = {
      :api => {
        :default_site => :osm,
        :osm => {
          :id => '1',
          :token => 'API TOKEN',
          :name => 'API NAME',
        },
        :ogm => {
          :id => '2',
          :token => 'API TOKEN 2',
          :name => 'API NAME 2',
        },
      },
      :cache => {
        :cache => OsmTest::Cache,
      },
    }
    Osm::configure(@CONFIGURATION)
    
    @api = Osm::Api.new('user_id', 'secret')
    Osm::Model.stub(:require_ability_to) {}
    Osm::Model.stub(:require_access_to_section) {}
  end
end


module OsmTest
  class Cache
    @@cache = {}
    def self.write(key, data, options={})
      @@cache[key] = data
    end
    def self.read(key)
      @@cache[key]
    end
    def self.exist?(key)
      @@cache.include?(key)
    end
    def self.delete(key)
      @@cache.delete(key)
    end
    def self.clear
      @@cache = {}
    end
    def self.inspect
      @@cache.inspect
    end
  end

  class DummyHttpResult
    def initialize(options={})
      @response = OsmTest::DummyHttpResponse.new(options[:response])
    end
    def response
      @response
    end
  end
  class DummyHttpResponse
    def initialize(options={})
      @options = options
    end
    def code
      @options[:code]
    end
    def body
      @options[:body]
    end
    def content_type
      @options[:content_type] || 'text/html'
    end
  end
end
