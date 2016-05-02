module Osm

  class ApiAccess < Osm::Model

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the API
    # @!attribute [rw] name
    #   @return [String] the name of the API
    # @!attribute [rw] permissions
    #   @return [Hash] the permissions assigned to this API by the user in OSM

    attribute :id, :type => Integer
    attribute :name, :type => String
    attribute :permissions, :default => {}

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0
    validates_presence_of :name

    validates :permissions, :hash => {:key_type => Symbol, :value_type => Array}


    # Get API access details for a given section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the details for
    # @!macro options_get
    # @return [Array<Osm::ApiAccess>]
    def self.get_all(api, section, options={})
      section_id = section.to_i
      cache_key = ['api_access', api.user_id, section_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        ids = cache_read(api, cache_key)
        return get_from_ids(api, ids, cache_key, section, options, :get_all)
      end

      data = api.perform_query("ext/settings/access/?action=getAPIAccess&sectionid=#{section_id}")

      permissions_map = {
        10  => [:read],
        20  => [:read, :write],
        100 => [:read, :write, :administer]
      }
      result = Array.new
      ids = Array.new
      data['apis'].each do |item|
        attributes = {}
        attributes[:id] = item['apiid'].to_i
        attributes[:name] = item['name']
        attributes[:permissions] = item['permissions'].is_a?(Hash) ? item['permissions'] : {}
  
        # Rubyify permissions hash
        attributes[:permissions].keys.each do |old_key|
          new_key = (old_key.to_sym rescue old_key)    # Get symbol of the key
          attributes[:permissions][new_key] = attributes[:permissions].delete(old_key)  # Change the key
          attributes[:permissions][new_key] = permissions_map[attributes[:permissions][new_key].to_i] || [] # Translate permissions value
        end
        attributes[:permissions].freeze

        this_item = new(attributes)
        result.push this_item
        ids.push this_item.id
        cache_write(api, [*cache_key, this_item.id], this_item)
      end
      cache_write(api, cache_key, ids)

      return result
    end


    # Get our API access details for a given section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the details for
    # @!macro options_get
    # @return [Osm::ApiAccess]
    def self.get_ours(api, section, options={})
      get(api, section, api.api_id, options)
    end


    # Get API Access for a given API
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the details for
    # @param [Osm::Api] for_api The api (or its ID) to get access for
    # @!macro options_get
    # @return [Osm::ApiAccess]
    def self.get(api, section, for_api, options={})
      section_id = section.to_i
      for_api_id = for_api.to_i
      cache_key = ['api_access', api.user_id, section_id, for_api]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      data = get_all(api, section_id, options)

      data.each do |item|
        return item if item.id == for_api_id
      end
      return nil
    end


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


  end # Class ApiAccess

end # Module
