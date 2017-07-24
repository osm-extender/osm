# Require gems
require 'active_attr'
require 'active_model'
require 'dirty_hashy'

# Require from standard ruby libraries
require 'date'
require 'json'
require 'net/http'
require 'time'


module OSM
  # Declare exceptions
  class APIError < RuntimeError
    class ConnectionError < APIError; end
    class InvalidUser < APIError; end
    class UnexpectedType < APIError; end
  end # class APIError
  class OSMError < RuntimeError
    class Forbidden < OSMError; end
    class ReadOnly < OSMError; end
    class NoActiveRoles < OSMError; end
    class NoCurrentTerm < OSMError
      # @!attribute [r] section_id
      #   @return [Integer] the id of the section causing the error
      attr_reader :section_id
      def initialize(message = nil, section_id = nil)
        super(message)
        @section_id = section_id
      end
    end # class NoCurrentTerm
    class NotFound < OSMError; end
  end # class OSMError
  class Error < RuntimeError
    class InvalidObject < Error; end
  end

  # Set constants
  OSM_DATE_FORMAT = '%Y-%m-%d'.freeze
  OSM_TIME_FORMAT = '%H:%M:%S'.freeze
  OSM_DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'.freeze
  OSM_DATE_FORMAT_HUMAN = '%d/%m/%Y'.freeze
  OSM_DATETIME_FORMAT_HUMAN = '%d/%m/%Y %H:%M:%S'.freeze
  OSM_TIME_REGEX = %r{\A(?:[0-1][0-9]|2[0-3]):[0-5][0-9]\Z}
  OSM_DATE_REGEX_UNANCHORED = %r{(?:[1-9]\d{3}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[1-2][0-9]|3[0-1]))|(?:(?:0?[1-9]|[1-2][0-9]|3[0-1])/(?:0?[1-9]|1[0-2])/(?:\d{2}|[1-9]\d{3}))}
  OSM_DATE_REGEX = %r{\A#{OSM::OSM_DATE_REGEX_UNANCHORED.to_s}\Z}
  subscription_level_names = {
    1 => 'Bronze',
    bronze: 'Bronze',
    2 => 'Silver',
    silver: 'Silver',
    3 => 'Gold',
    gold: 'Gold',
    4 => 'Gold+',
    gold_plus: 'Gold+'
  }
  subscription_level_names.default = 'Unknown'
  SUBSCRIPTION_LEVEL_NAMES = subscription_level_names
  SUBSCRIPTION_LEVELS = [nil, :bronze, :silver, :gold, :gold_plus].freeze
end

# Require file for this gem
require File.join(File.dirname(__FILE__), '..', 'version')
Dir[File.join(File.dirname(__FILE__), '*_validator.rb')].each { |file| require file }
# These must be included before the rest
require File.join(File.dirname(__FILE__), 'osm', 'model')
require File.join(File.dirname(__FILE__), 'osm', 'flexi_record')
require File.join(File.dirname(__FILE__), 'osm', 'member', 'contact')
require File.join(File.dirname(__FILE__), 'osm', 'member', 'emailable_contact')
require File.join(File.dirname(__FILE__), 'osm', 'member', 'enableable_emailable_contact')
require File.join(File.dirname(__FILE__), 'osm', 'member', 'enableable_phoneable_contact')
require File.join(File.dirname(__FILE__), 'osm', 'member')
require File.join(File.dirname(__FILE__), 'osm', 'meeting', 'activity')
require File.join(File.dirname(__FILE__), 'osm', 'meeting', 'badge_link')
require File.join(File.dirname(__FILE__), 'osm', 'invoice', 'item')
require File.join(File.dirname(__FILE__), 'osm', 'event', 'badge_link')
require File.join(File.dirname(__FILE__), 'osm', 'event', 'column')
require File.join(File.dirname(__FILE__), 'osm', 'email', 'delivery_report', 'recipient.rb')
require File.join(File.dirname(__FILE__), 'osm', 'activity', 'badge')
require File.join(File.dirname(__FILE__), 'osm', 'activity', 'file')
require File.join(File.dirname(__FILE__), 'osm', 'activity', 'version')
require File.join(File.dirname(__FILE__), 'osm', 'badge', 'requirement.rb')
require File.join(File.dirname(__FILE__), 'osm', 'badge', 'requirement_module.rb')
require File.join(File.dirname(__FILE__), 'osm', 'badge')

# And finally the rest
Dir[File.join(File.dirname(__FILE__), 'osm', '**', '*.rb')].each { |file| require file }


module OSM

  private

  def self.make_datetime(date: nil, time: nil, ignore_epoch: false)
    date = nil if date.nil? || date.empty? || (ignore_epoch && epoch_date?(date))
    time = nil if time.nil? || time.empty?
    if !date.nil? && !time.nil?
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


  def self.parse_date(date, ignore_epoch: false)
    return nil if date.nil? || date.empty? || (ignore_epoch && epoch_date?(date))
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
    fail ArgumentError, 'You did not pass in a hash' unless hash_in.is_a?(Hash)

    hash_out = {}
    hash_in.each do |key, value|
      key = key.to_s unless key.is_a?(Symbol)
      hash_out[key.to_sym] = value
    end
    hash_out
  end

  def self.make_permissions_hash(permissions)
    return {} unless permissions.is_a?(Hash)

    permissions_map = {
      10  => [:read],
      20  => [:read, :write],
      100 => [:read, :write, :administer]
    }

    permissions.inject({}) do |new_hash, (key, value)|
      if ['badge', 'member', 'user', 'register', 'contact', 'programme', 'events', 'flexi', 'finance', 'quartermaster'].include?(key)
        # This is a permission we care about
        new_hash[key.to_sym] = permissions_map[value.to_i]
      end
      new_hash
    end
  end

  def self.epoch_date?(date)
    epoch = Date.new(1970, 1, 1)
    date = date.strftime('%Y-%m-%d') if date.respond_to?(:strftime)
    Date.parse(date).eql?(epoch)
  end

  def self.inspect_instance(instance, options={})
    replace_with = options[:replace_with] || {}

    values = instance.attributes.sort.map do |(k, v)|
      (replace_with.keys.include?(k) && !v.nil?) ? "#{k}.#{replace_with[k]}: #{v.try(replace_with[k]).inspect}" : "#{k}: #{v.inspect}"
    end

    "#<#{instance.class.name} #{values.join(', ')} >"
  end

end # Module
