# Require gems
require 'active_attr'
require 'active_support'
require 'active_model'
require 'date'
require 'httparty'
require 'dirty_hashy'


module Osm
  # Declare exceptions
  class Error < Exception; end
  class ConnectionError < Error; end
  class Forbidden < Osm::Error; end
  class NoActiveRoles < Osm::Error; end
  class ArgumentIsInvalid < ArgumentError; end
  class ObjectIsInvalid < Error; end
  class Osm::Error::NoCurrentTerm < Osm::Error
    # @!attribute [r] section_id
    #   @return [Fixnum] the id of the section causing the error
    attr_reader :section_id
    def initialize(message = nil, section_id = nil)
      super(message)
      @section_id = section_id
    end
  end

  private
  # Set constants
  OSM_EPOCH = '1970-01-01'
  OSM_EPOCH_HUMAN = '1970-01-01'
  OSM_DATE_FORMAT = '%Y-%m-%d'
  OSM_TIME_FORMAT = '%H:%M:%S'
  OSM_DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
  OSM_DATE_FORMAT_HUMAN = '%d/%m/%Y'
  OSM_DATETIME_FORMAT_HUMAN = '%d/%m/%Y %H:%M:%S'
  OSM_TIME_REGEX = /\A(?:[0-1][0-9]|2[0-3]):[0-5][0-9]\Z/
  OSM_DATE_REGEX_UNANCHORED = /(?:[1-9]\d{3}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[1-2][0-9]|3[0-1]))|(?:(?:0?[1-9]|[1-2][0-9]|3[0-1])\/(?:0?[1-9]|1[0-2])\/(?:\d{2}|[1-9]\d{3}))/
  OSM_DATE_REGEX = /\A#{Osm::OSM_DATE_REGEX_UNANCHORED.to_s}\Z/
  subscription_level_names = {
    1 => 'Bronze',
    :bronze => 'Bronze',
    2 => 'Silver',
    :silver => 'Silver',
    3 => 'Gold',
    :gold => 'Gold',
    4 => 'Gold+',
    :gold_plus => 'Gold+',
  }
  subscription_level_names.default = 'Unknown'
  SUBSCRIPTION_LEVEL_NAMES = subscription_level_names
  SUBSCRIPTION_LEVELS = [nil, :bronze, :silver, :gold, :gold_plus]
end

# Require file for this gem
require File.join(File.dirname(__FILE__), '..', 'version')
Dir[File.join(File.dirname(__FILE__) , '*_validator.rb')].each {|file| require file }
['model', 'flexi_record'].each do |file| # These must be included before the rest
  require File.join(File.dirname(__FILE__), 'osm', file)
end
Dir[File.join(File.dirname(__FILE__) , 'osm', '*.rb')].each {|file| require file }


module Osm

    # Configure the options used by classes in the module
    # @param [Hash] options
    # @option options [Hash] :api Default options for accessing the API
    # @option options[:api] [Symbol] :default_site whether to use OSM (if :osm) or OGM (if :ogm) by default
    # @option options[:api] [Hash] :osm (optional but :osm_api or :ogm_api must be present) the api data for OSM
    # @option options[:api][:osm] [String] :id the apiid given to you for using the OSM id
    # @option options[:api][:osm] [String] :token the token which goes with the above api
    # @option options[:api][:osm] [String] :name the name displayed in the External Access tab of OSM
    # @option options[:api] [Hash] :ogm (optional but :osm_api or :ogm_api must be present) the api data for OGM
    # @option options[:api][:ogm] [String] :id the apiid given to you for using the OGM id
    # @option options[:api][:ogm] [String] :token the token which goes with the above api
    # @option options[:api][:ogm] [String] :name the name displayed in the External Access tab of OGM
    # @option options[:api] [Boolean] :debug if true debugging info is output (optional, default = false)
    # @option options [Hash] :cache_config (optional) How classes in the module will cache data. Whilst this is optional you should remember that caching is required to use the OSM API.
    # @option options[:cache] [Class] :cache An instance of a cache class, must provide the methods (exist?, delete, write, read), for details see Rails.cache.
    # @option options[:cache] [Fixnum] :ttl (optional, default = 30.minutes) The default TTL value for the cache, note that some items are cached for twice this time and others are cached for half this time (in seconds)
    # @option options[:cache] [String] :prepend_to_key (optional, default = 'OSMAPI') Text to prepend to the key used to store data in the cache
    # @return nil
    def self.configure(options)
      Osm::Model.configure(options[:cache])
      Osm::Api.configure(options[:api])
      nil
    end


  private  
  def self.make_array_of_symbols(array)
    array.each_with_index do |item, index|
      array[index] = item.to_sym
    end
  end

  def self.make_datetime(date, time, options={})
    date = nil if date.nil? || date.empty? || (!options[:ignore_epoch] && epoch_date?(date))
    time = nil if time.nil? || time.empty?
    if (!date.nil? && !time.nil?)
      begin
        return DateTime.strptime((date + ' ' + time), OSM_DATETIME_FORMAT)
      rescue ArgumentError
        return nil
      end
    elsif !date.nil?
      begin
        return DateTime.strptime(date, (date.include?('-') ? OSM_DATE_FORMAT : OSM_DATE_FORMAT_HUMAN))
      rescue ArgumentError
        return nil
      end
    else
      return nil
    end
  end

  def self.parse_datetime(date_time)
    return nil if date_time.nil? || date_time.empty?
    begin
      return DateTime.strptime(date_time, OSM_DATETIME_FORMAT)
    rescue ArgumentError
      return nil
    end
  end


  def self.parse_date(date, options={})
    return nil if date.nil? || date.empty? || (!options[:ignore_epoch] && epoch_date?(date))
    begin
      return Date.strptime(date, (date.include?('-') ? OSM_DATE_FORMAT : OSM_DATE_FORMAT_HUMAN))
    rescue ArgumentError
      return nil
    end
  end

  def self.to_i_or_nil(item)
    return nil if item.nil?
    begin
      return item.to_i
    rescue
      return nil
    end
  end

  def self.symbolize_hash(hash_in)
    raise ArgumentError, 'You did not pass in a hash' unless hash_in.is_a?(Hash)

    hash_out = {}
    hash_in.each do |key, value|
      hash_out[key.to_sym] = value
    end
    hash_out
  end

  def self.make_permissions_hash(permissions)
    return {} unless permissions.is_a?(Hash)

    permissions_map = {
      10  => [:read],
      20  => [:read, :write],
      100 => [:read, :write, :administer],
    }

    return permissions.inject({}) do |new_hash, (key, value)|
      if ["badge", "member", "user", "register", "contact", "programme","events", "flexi", "finance", "quartermaster"].include?(key)
        # This is a permission we care about
        new_hash[key.to_sym] = permissions_map[value.to_i]
      end
      new_hash
    end
  end

  def self.epoch_date?(date)
    [OSM_EPOCH, OSM_EPOCH_HUMAN].include?(date)
  end

  def self.inspect_instance(instance, options={})
    replace_with = options[:replace_with] || {}

    values = instance.attributes.sort.map{ |(k,v)|
      (replace_with.keys.include?(k) && !v.nil?) ? "#{k}.#{replace_with[k]}: #{v.try(replace_with[k])}" : "#{k}: #{v.inspect}"
    }

    return "#<#{instance.class.name} #{values.join(', ')} >"
  end

end # Module
