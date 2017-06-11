module Osm

  class ApiAccess < Osm::Model

    # @!attribute [rw] id
    #   @return [Integer] the id for the API
    # @!attribute [rw] name
    #   @return [String] the name of the API
    # @!attribute [rw] permissions
    #   @return [Hash] the permissions assigned to this API by the user in OSM

    attribute :id, type: Integer
    attribute :name, type: String
    attribute :permissions, default: {}

    validates_numericality_of :id, only_integer: true, greater_than: 0
    validates_presence_of :name

    validates :permissions, hash: { key_type: Symbol, value_type: Array }


    # Get API access details for a given section
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the details for
    # @!macro options_get
    # @return [Array<Osm::ApiAccess>]
    def self.get_all(api:, section:, no_read_cache: false)
      section_id = section.to_i
      cache_key = ['api_access', api.user_id, section_id]

      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("ext/settings/access/?action=getAPIAccess&sectionid=#{section_id}")

        permissions_map = {
          10  => [:read],
          20  => [:read, :write],
          100 => [:read, :write, :administer]
        }

        data['apis'].map do |item|
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

          new attributes
        end # data.map
      end # cache_fetch
    end


    # Get our API access details for a given section
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the details for
    # @!macro options_get
    # @return [Osm::ApiAccess]
    def self.get_ours(api:, section:, no_read_cache: false)
      get(api: api, section: section, for_api: api.api_id, no_read_cache: no_read_cache)
    end


    # Get API Access for a given API
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the details for
    # @param for_api [Osm::Api] The api (or its ID) to get access for
    # @!macro options_get
    # @return [Osm::ApiAccess]
    def self.get(api:, section:, for_api:, no_read_cache: false)
      section_id = section.to_i
      for_api_id = for_api.to_i
      cache_key = ['api_access', api.user_id, section_id, for_api]

      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = get_all(api: api, section: section_id, no_read_cache: no_read_cache)
        found = nil
        data.each do |item|
          found = item if item.id == for_api_id
        end
        found
      end # cache fetch
    end


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


  end # Class ApiAccess

end # Module
