require 'simplecov'
SimpleCov.coverage_dir(File.join('tmp', 'coverage'))
SimpleCov.start do
  add_filter 'spec/'
end

require 'coveralls' and Coveralls.wear! if ENV['TRAVIS']


require 'fakeweb'
require 'active_attr/rspec'

require 'osm'

FakeWeb.allow_net_connect = false
FakeWeb.allow_net_connect = %r[^https://coveralls.io] # Allow coveralls to report coverage


RSpec.configure do |config|

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec  do |configuration|
    # Using the expect syntax is preferable to the should syntax in some cases.
    # The problem here is that the :should syntax that RSpec uses can fail in
    # the case of proxy objects, and objects that include the delegate module.
    # Essentially it requires that we define methods on every object in the
    # system. Not owning every object means that we cannot ensure this works in
    # a consistent manner. The expect syntax gets around this problem by not
    # relying on RSpec specific methods being defined on every object in the
    # system.
    configuration.syntax = [:expect, :should]
  end

  config.before(:each) do
    FakeWeb.clean_registry
    OsmTest::Cache.clear

    $api = Osm::Api.new(
      site:             :osm,
      api_id:           '1',
      api_secret:       'API-SECRET',
      name:             'API NAME',
      debug:            false,
      http_user_agent:  'HTTP-USER-AGENT',
      user_id:          '2',
      user_secret:      'USER-SECRET',
    )

    Osm::Model.cache = OsmTest::Cache
    Osm::Model.prepend_to_cache_key = 'OSMAPI'
    Osm::Model.cache_ttl = 600

    Osm::Model.stub(:require_ability_to).and_return(nil)
    Osm::Model.stub(:require_access_to_section).and_return(nil)
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
    def self.fetch(key, options={})
      value = read(key)
      return value unless value.nil?
      write(key, yield)
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
  end # class Cache
end # module OsmTest
