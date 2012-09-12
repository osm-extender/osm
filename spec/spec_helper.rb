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
  end
end
