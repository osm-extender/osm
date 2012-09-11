require 'active_attr'
require 'date'

require File.join(File.dirname(__FILE__), '..', 'version')
Dir[File.join(File.dirname(__FILE__) , 'osm', '*.rb')].each {|file| require file }


module Osm
  OSM_EPOCH_S = '1970-01-01'
  OSM_DATE_FORMAT = '%Y-%m-%d'
  OSM_DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'

  class Error < Exception; end
  class ConnectionError < Error; end
  class ArgumentIsInvalid < ArgumentError; end

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

  def self.make_datetime(date, time, options={})
    date = nil if date.nil? || date.empty? || (date.eql?(OSM_EPOCH_S) && !options[:ignore_epoch])
    time = nil if time.nil? || time.empty?
    if (!date.nil? && !time.nil?)
      begin
        return DateTime.strptime((date + ' ' + time), OSM_DATETIME_FORMAT)
      rescue ArgumentError
        return nil
      end
    elsif !date.nil?
      begin
        return DateTime.strptime(date, OSM_DATE_FORMAT)
      rescue ArgumentError
        return nil
      end
    else
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

  def self.is_array_of?(ar, ty)
    return false unless ar.is_a?(Array)
    ar.each do |it|
      return false unless it.is_a?(ty)
    end
    return true
  end

end # Module
