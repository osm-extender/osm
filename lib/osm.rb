require 'active_attr'
require 'active_support'
require 'active_model'
require 'date'
require 'httparty'


module Osm
  class Error < Exception; end
  class ConnectionError < Error; end
  class ArgumentIsInvalid < ArgumentError; end

  private
  OSM_EPOCH_S = '1970-01-01'
  OSM_DATE_FORMAT = '%Y-%m-%d'
  OSM_TIME_FORMAT = '%H:%M:%S'
  OSM_DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
  OSM_TIME_REGEX = /\A(?:[0-1][0-9]|2[0-3]):[0-5][0-9]\Z/
  OSM_DATE_REGEX = /\A\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[1-2][0-9]|3[0-1])\Z/
end

require File.join(File.dirname(__FILE__), '..', 'version')
Dir[File.join(File.dirname(__FILE__) , '*_validator.rb')].each {|file| require file }
Dir[File.join(File.dirname(__FILE__) , 'osm', '*.rb')].each {|file| require file }


module Osm

    # Configure the options used by classes in the module
    # @param [Hash] options
    # @option options [Hash] :api Default options for accessing the API
    # @option options[:api] [Symbol] :default_site wether to use OSM (if :osm) or OGM (if :ogm) by default
    # @option options[:api] [Hash] :osm (optional but :osm_api or :ogm_api must be present) the api data for OSM
    # @option options[:api][:osm] [String] :id the apiid given to you for using the OSM id
    # @option options[:api][:osm] [String] :token the token which goes with the above api
    # @option options[:api][:osm] [String] :name the name displayed in the External Access tab of OSM
    # @option options[:api] [Hash] :ogm (optional but :osm_api or :ogm_api must be present) the api data for OGM
    # @option options[:api][:ogm] [String] :id the apiid given to you for using the OGM id
    # @option options[:api][:ogm] [String] :token the token which goes with the above api
    # @option options[:api][:ogm] [String] :name the name displayed in the External Access tab of OGM
    # @option options[:api] [Boolean] :debug if true debugging info is output (optional, default = false)
    # @return nil
    def self.configure(options)
      Osm::Api.configure(options[:api])
      nil
    end


  private  
  def self.make_array_of_symbols(array)
    array.each_with_index do |item, index|
      array[index] = item.to_sym
    end
  end

  def self.find_current_term_id(api, section_id, data={})
    terms = api.get_terms(data)

    # Return the term we are currently in
    unless terms.nil?
      terms.each do |term|
        return term.id if (term.section_id == section_id) && term.current?
      end
    end

    raise Error, 'There is no current term for the section.'
  end

  ###def self.make_datetime(date, time, options={})
  ###  date = nil if date.nil? || date.empty? || (date.eql?(OSM_EPOCH_S) && !options[:ignore_epoch])
  ###  time = nil if time.nil? || time.empty?
  ###  if (!date.nil? && !time.nil?)
  ###    begin
  ###      return DateTime.strptime((date + ' ' + time), OSM_DATETIME_FORMAT)
  ###    rescue ArgumentError
  ###      return nil
  ###    end
  ###  elsif !date.nil?
  ###    begin
  ###      return DateTime.strptime(date, OSM_DATE_FORMAT)
  ###    rescue ArgumentError
  ###      return nil
  ###    end
  ###  else
  ###    return nil
  ###  end
  ###end

  def self.parse_date_time(date_time)
    return nil if date_time.nil? || date_time.empty?
    begin
      return DateTime.strptime((date_time), OSM_DATETIME_FORMAT)
    rescue ArgumentError
      return nil
    end
  end


  def self.parse_date(date, options={})
    return nil if date.nil? || date.empty? || (date.eql?(OSM_EPOCH_S) && !options[:ignore_epoch])
    begin
      return Date.strptime(date, OSM_DATE_FORMAT)
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

end # Module
